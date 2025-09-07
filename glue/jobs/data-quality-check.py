import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import boto3
import json
from datetime import datetime

# Import data quality rules
# IMPORTANT: For Glue, ensure 'quality_rules.py' (or its containing 'rules' directory)
# is added to the Job's 'Python library path' or 'Python files' in Glue Job configuration.
from quality_rules import get_sql_rules


# Initialize Glue context
args = getResolvedOptions(
    sys.argv,
    [
        "JOB_NAME",
        "S3_INPUT_PATH",
        "S3_ERROR_PATH",
        "DATA_QUALITY_LAMBDA_ARN",
        "SNS_TOPIC_ARN",  # New argument for SNS Topic ARN
    ],
)
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# --- Configuration ---
s3_input_path = args["S3_INPUT_PATH"]
s3_error_path = args["S3_ERROR_PATH"]
data_quality_lambda_arn = args["DATA_QUALITY_LAMBDA_ARN"]
sns_topic_arn = args["SNS_TOPIC_ARN"]

lambda_client = boto3.client("lambda")
sns_client = boto3.client("sns")

all_errors_found = []  # To collect all errors from SQL and Python checks

# --- Read data from S3 ---
print(f"Reading data from: {s3_input_path}")
try:
    datasource = glueContext.create_dynamic_frame.from_options(
        format_options={"quoteChar": '"', "withHeader": True, "separator": ","},
        connection_type="s3",
        format="csv",
        connection_options={"paths": [s3_input_path], "recurse": True},
        transformation_ctx="datasource_ctx",
    )
    df = datasource.toDF()
    df.printSchema()
    df.show(5)
    df.createOrReplaceTempView("temp_data")  # Create temp view for SQL checks
except Exception as e:
    print(f"Error reading data from S3: {e}")
    # Send critical error notification if data cannot be read
    sns_client.publish(
        TopicArn=sns_topic_arn,
        Subject=f"CRITICAL DQ ERROR: Glue Job {args['JOB_NAME']} - Data Read Failure",
        Message=f"Failed to read data from {s3_input_path}. Error: {e}",
    )
    job.commit()
    sys.exit(1)  # Exit job if data cannot be read


# --- Execute SQL Data Quality Rules ---
print("Executing SQL data quality rules...")
sql_rules = get_sql_rules()
for rule_name, rule_details in sql_rules.items():
    query = rule_details["query"]
    error_type = rule_details["error_type"]
    description = rule_details["description"]

    print(f"  - Running SQL Rule: {rule_name} ({description})")
    try:
        bad_records_df = spark.sql(query)
        if bad_records_df.count() > 0:
            print(
                f"    -> Found {bad_records_df.count()} records for rule: {rule_name}"
            )
            # Write bad records to a specific error path
            error_output_path = f"{s3_error_path}/{error_type.lower()}/{datetime.now().strftime('%Y%m%d%H%M%S')}/"
            bad_records_df.write.mode("append").csv(error_output_path)

            # Collect error details
            all_errors_found.append(
                {
                    "rule_name": rule_name,
                    "error_type": error_type,
                    "description": description,
                    "count": bad_records_df.count(),
                    "error_path": error_output_path,
                    "source_file": s3_input_path,
                }
            )
    except Exception as e:
        print(f"    -> Error executing SQL rule {rule_name}: {e}")
        all_errors_found.append(
            {
                "rule_name": rule_name,
                "error_type": "SQL_EXECUTION_ERROR",
                "description": f"Failed to execute SQL rule: {description}",
                "details": str(e),
                "source_file": s3_input_path,
            }
        )


# --- Invoke Lambda for Python Data Quality Rules ---
print("Invoking Lambda for Python data quality rules...")
payload = {
    "s3_path": s3_input_path,
    "error_s3_path": s3_error_path,  # Lambda might use this for context, though Glue handles writing
}

try:
    response = lambda_client.invoke(
        FunctionName=data_quality_lambda_arn,
        InvocationType="RequestResponse",  # Use 'RequestResponse' to get results back
        Payload=json.dumps(payload),
    )
    response_payload = json.loads(response["Payload"].read().decode("utf-8"))

    if response_payload.get("status") == "FAILED" and response_payload.get(
        "errors_found"
    ):
        print(
            f"Lambda reported {len(response_payload.get('details', []))} Python data quality issues."
        )
        # Lambda should return structured errors, append them to all_errors_found
        for error_detail in response_payload.get("details", []):
            all_errors_found.append(
                {
                    "rule_name": error_detail.get("rule_name", "Python_Rule"),
                    "error_type": error_detail.get("error_type", "PYTHON_DQ_ERROR"),
                    "description": error_detail.get(
                        "description", "Python data quality check failed."
                    ),
                    "details": error_detail.get("details", "No specific details."),
                    "source_file": s3_input_path,
                }
            )
    else:
        print("Lambda reported no Python data quality issues.")

except Exception as e:
    print(f"Error invoking Lambda {data_quality_lambda_arn}: {e}")
    all_errors_found.append(
        {
            "rule_name": "LAMBDA_INVOCATION_ERROR",
            "error_type": "LAMBDA_ERROR",
            "description": f"Failed to invoke Lambda for Python DQ checks: {str(e)}",
            "source_file": s3_input_path,
        }
    )


# --- Send SNS Notification if Errors Found ---
if all_errors_found:
    print(
        f"Total {len(all_errors_found)} data quality issues found. Sending SNS notification."
    )
    sns_subject = f"Data Quality Alert for {args['JOB_NAME']} - {len(all_errors_found)} Issues Found"
    sns_message = {
        "job_name": args["JOB_NAME"],
        "input_path": s3_input_path,
        "timestamp": datetime.now().isoformat(),
        "total_errors": len(all_errors_found),
        "errors": all_errors_found,
    }
    try:
        sns_client.publish(
            TopicArn=sns_topic_arn,
            Subject=sns_subject,
            Message=json.dumps(sns_message, indent=2),
        )
        print("SNS notification sent successfully.")
    except Exception as e:
        print(f"Failed to send SNS notification: {e}")
else:
    print("No data quality issues found. No SNS notification sent.")

# --- Finalize Job ---
job.commit()
