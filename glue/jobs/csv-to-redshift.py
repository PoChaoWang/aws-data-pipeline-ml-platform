import sys
import boto3
import pandas as pd
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from pyspark.context import SparkContext
from awsglue.job import Job
import time
from botocore.exceptions import ClientError

# --- Helper Functions ---


def get_redshift_columns(
    redshift_data_client, cluster_id, database, db_user, table_name
):
    """Queries Redshift's information schema to get existing column names."""
    query = f"""SELECT column_name, data_type FROM information_schema.columns 
               WHERE table_name = '{table_name.lower()}' ORDER BY ordinal_position;"""
    try:
        response = redshift_data_client.execute_statement(
            ClusterIdentifier=cluster_id, Database=database, DbUser=db_user, Sql=query
        )

        query_id = response["Id"]
        max_attempts = 300  # 5 minutes timeout
        attempt = 0

        while attempt < max_attempts:
            status_response = redshift_data_client.describe_statement(Id=query_id)
            status = status_response["Status"]

            if status == "FINISHED":
                records = redshift_data_client.get_statement_result(Id=query_id)[
                    "Records"
                ]
                return [
                    (record[0]["stringValue"], record[1]["stringValue"])
                    for record in records
                ]
            elif status in ["FAILED", "ABORTED"]:
                error_msg = status_response.get("Error", "Unknown error")
                raise Exception(f"Redshift query failed: {error_msg}")

            time.sleep(1)
            attempt += 1

        raise Exception("Query timeout after 5 minutes")

    except redshift_data_client.exceptions.ResourceNotFoundException:
        # Table doesn't exist yet
        return []


def execute_redshift_query(redshift_data_client, cluster_id, database, db_user, query):
    """Executes a SQL statement on Redshift and waits for completion."""
    try:
        response = redshift_data_client.execute_statement(
            ClusterIdentifier=cluster_id, Database=database, DbUser=db_user, Sql=query
        )

        query_id = response["Id"]
        max_attempts = 300  # 5 minutes timeout
        attempt = 0

        while attempt < max_attempts:
            status_response = redshift_data_client.describe_statement(Id=query_id)
            status = status_response["Status"]

            if status == "FINISHED":
                print(f"Successfully executed query: {query[:80]}...")
                return True
            elif status in ["FAILED", "ABORTED"]:
                error_msg = status_response.get("Error", "Unknown error")
                raise Exception(f"Redshift query failed: {error_msg}")

            time.sleep(1)
            attempt += 1

        raise Exception("Query timeout after 5 minutes")

    except ClientError as e:
        print(f"AWS Client Error: {e}")
        raise


def infer_redshift_type(sample_values):
    """Simple type inference for Redshift columns based on sample data."""
    # This is a basic implementation - you might want to make it more sophisticated
    for val in sample_values:
        if pd.isna(val):
            continue
        try:
            int(val)
            return "INTEGER"
        except (ValueError, TypeError):
            try:
                float(val)
                return "FLOAT"
            except (ValueError, TypeError):
                # Check for date patterns
                if len(str(val)) == 10 and "-" in str(val):
                    return "DATE"
                elif len(str(val)) > 50:
                    return "VARCHAR(500)"
                else:
                    return "VARCHAR(256)"
    return "VARCHAR(256)"


def move_file_to_error(bucket_name, source_key, file_name):
    """Move file to error directory for debugging."""
    try:
        s3_resource = boto3.resource("s3")
        error_key = f"error/{file_name}"
        copy_source = {"Bucket": bucket_name, "Key": source_key}
        s3_resource.Object(bucket_name, error_key).copy_from(CopySource=copy_source)
        s3_resource.Object(bucket_name, source_key).delete()
        print(f"File moved to error directory: s3://{bucket_name}/{error_key}")
    except Exception as move_error:
        print(f"Failed to move file to error directory: {move_error}")


# --- Main job logic ---
def main():
    args = getResolvedOptions(
        sys.argv,
        [
            "JOB_NAME",
            "S3_SOURCE_PATH",
            "REDSHIFT_CLUSTER_ID",
            "REDSHIFT_DATABASE",
            "REDSHIFT_USER",
            "REDSHIFT_TABLE",
            "PRIMARY_KEY",
            "REDSHIFT_CONNECTION_NAME",  # Make connection name configurable
        ],
    )

    # Initialize contexts
    sc = SparkContext()
    glueContext = GlueContext(sc)
    job = Job(glueContext)
    job.init(args["JOB_NAME"], args)

    # Parameters
    s3_source_path = args["S3_SOURCE_PATH"]
    target_table = args["REDSHIFT_TABLE"]
    primary_key = args["PRIMARY_KEY"]
    connection_name = args["REDSHIFT_CONNECTION_NAME"]
    bucket_name = s3_source_path.split("/")[2]
    source_key = "/".join(s3_source_path.split("/")[3:])
    file_name = s3_source_path.split("/")[-1]
    staging_table = f"{target_table}_staging_{int(time.time())}"

    redshift_data = boto3.client("redshift-data")
    staging_table_created = False

    try:
        print(f"Starting processing for file: {s3_source_path}")

        # 1. Read sample data for type inference
        s3_client = boto3.client("s3")
        obj = s3_client.get_object(Bucket=bucket_name, Key=source_key)
        sample_df = pd.read_csv(obj["Body"], nrows=100)  # Sample first 100 rows
        csv_columns = sample_df.columns.tolist()

        # 2. Synchronize Schema
        print("Synchronizing schema...")
        existing_columns = get_redshift_columns(
            redshift_data,
            args["REDSHIFT_CLUSTER_ID"],
            args["REDSHIFT_DATABASE"],
            args["REDSHIFT_USER"],
            target_table,
        )

        existing_column_names = (
            [col[0] for col in existing_columns] if existing_columns else []
        )

        if not existing_columns:
            # Table doesn't exist, create it with inferred types
            print(f"Creating new table: {target_table}")
            column_definitions = []
            for col in csv_columns:
                if col in sample_df.columns:
                    col_type = infer_redshift_type(sample_df[col].dropna().head(10))
                else:
                    col_type = "VARCHAR(256)"
                column_definitions.append(f'"{col}" {col_type}')

            columns_with_types = ", ".join(column_definitions)
            create_query = f'CREATE TABLE {target_table} ({columns_with_types}, PRIMARY KEY ("{primary_key}"));'
            execute_redshift_query(
                redshift_data,
                args["REDSHIFT_CLUSTER_ID"],
                args["REDSHIFT_DATABASE"],
                args["REDSHIFT_USER"],
                create_query,
            )
        else:
            # Table exists, add new columns
            new_columns = [
                col for col in csv_columns if col not in existing_column_names
            ]
            if new_columns:
                print(f"Adding new columns: {new_columns}")
                for col in new_columns:
                    if col in sample_df.columns:
                        col_type = infer_redshift_type(sample_df[col].dropna().head(10))
                    else:
                        col_type = "VARCHAR(256)"
                    alter_query = (
                        f'ALTER TABLE {target_table} ADD COLUMN "{col}" {col_type};'
                    )
                    execute_redshift_query(
                        redshift_data,
                        args["REDSHIFT_CLUSTER_ID"],
                        args["REDSHIFT_DATABASE"],
                        args["REDSHIFT_USER"],
                        alter_query,
                    )

        # 3. Create staging table
        print(f"Creating staging table: {staging_table}")
        create_staging_query = f"CREATE TABLE {staging_table} (LIKE {target_table});"
        execute_redshift_query(
            redshift_data,
            args["REDSHIFT_CLUSTER_ID"],
            args["REDSHIFT_DATABASE"],
            args["REDSHIFT_USER"],
            create_staging_query,
        )
        staging_table_created = True

        # 4. Load data into staging table
        print(f"Loading data into staging table: {staging_table}")
        dynamic_frame = glueContext.create_dynamic_frame.from_options(
            connection_type="s3",
            connection_options={"paths": [s3_source_path]},
            format="csv",
            format_options={"withHeader": True},
        )

        glueContext.write_dynamic_frame.from_jdbc_conf(
            frame=dynamic_frame,
            catalog_connection=connection_name,
            connection_options={
                "dbtable": staging_table,
                "database": args["REDSHIFT_DATABASE"],
            },
            redshift_tmp_dir=f"s3://{bucket_name}/temp/",
        )

        # 5. Perform the UPSERT with better transaction handling
        print("Performing UPSERT operation...")

        # Use single transaction for all operations
        upsert_query = f"""
        BEGIN;
        DELETE FROM {target_table} 
        WHERE "{primary_key}" IN (SELECT "{primary_key}" FROM {staging_table});
        
        INSERT INTO {target_table} SELECT * FROM {staging_table};
        COMMIT;
        """

        execute_redshift_query(
            redshift_data,
            args["REDSHIFT_CLUSTER_ID"],
            args["REDSHIFT_DATABASE"],
            args["REDSHIFT_USER"],
            upsert_query,
        )

        print("UPSERT completed successfully.")

        # 6. Move processed file to processed directory
        s3_resource = boto3.resource("s3")
        processed_key = f"processed/{file_name}"
        copy_source = {"Bucket": bucket_name, "Key": source_key}
        s3_resource.Object(bucket_name, processed_key).copy_from(CopySource=copy_source)
        s3_resource.Object(bucket_name, source_key).delete()
        print(f"File moved to processed directory: s3://{bucket_name}/{processed_key}")

    except Exception as e:
        print(f"ERROR: Failed to process file {s3_source_path}. Reason: {str(e)}")
        move_file_to_error(bucket_name, source_key, file_name)

        # Rollback any transaction that might be in progress
        try:
            execute_redshift_query(
                redshift_data,
                args["REDSHIFT_CLUSTER_ID"],
                args["REDSHIFT_DATABASE"],
                args["REDSHIFT_USER"],
                "ROLLBACK;",
            )
        except:
            pass  # Rollback might fail if no transaction is active

        sys.exit(1)

    finally:
        # Clean up staging table
        if staging_table_created:
            print(f"Dropping staging table: {staging_table}")
            try:
                execute_redshift_query(
                    redshift_data,
                    args["REDSHIFT_CLUSTER_ID"],
                    args["REDSHIFT_DATABASE"],
                    args["REDSHIFT_USER"],
                    f"DROP TABLE IF EXISTS {staging_table};",
                )
            except Exception as cleanup_e:
                print(f"Failed to drop staging table during cleanup: {cleanup_e}")

    job.commit()


if __name__ == "__main__":
    main()
