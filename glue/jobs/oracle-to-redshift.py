
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv, ['JOB_NAME', 'S3_SOURCE_PATH', 'REDSHIFT_CLUSTER_ID', 'REDSHIFT_DATABASE', 'REDSHIFT_USER', 'REDSHIFT_TABLE'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Get job parameters
s3_source_path = args['S3_SOURCE_PATH']
redshift_cluster_id = args['REDSHIFT_CLUSTER_ID']
redshift_database = args['REDSHIFT_DATABASE']
redshift_user = args['REDSHIFT_USER']
redshift_table = args['REDSHIFT_TABLE']

# DMS typically creates a folder structure for each table.
# This example assumes you are processing one table. You may need to adjust this.
s3_input_path = f"{s3_source_path}/{args['ORACLE_SCHEMA']}/{args['ORACLE_TABLE']}/"

# Create a DynamicFrame from the S3 data (assuming Parquet format from DMS)
dynamic_frame = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    connection_options={"paths": [s3_input_path]},
    format="parquet"
)

# TODO: Add transformations if needed

# Write to Redshift
glueContext.write_dynamic_frame.from_jdbc_conf(
    frame=dynamic_frame,
    catalog_connection="redshift-connection", # This must be configured in Glue
    connection_options={
        "dbtable": redshift_table,
        "database": redshift_database
    },
    redshift_tmp_dir=f"s3://{args['S3_BUCKET_NAME']}/temp/"
)

job.commit()
