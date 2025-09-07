
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import boto3

# Get job arguments
args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'REDSHIFT_CONNECTION_NAME',
    'TEMP_S3_DIR',
    'OUTPUT_S3_PATH'
])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# SQL to extract and join data from Redshift
# This query should be customized to join user and CRM data
sql_query = """
SELECT 
    u.user_id,
    u.age,
    u.gender,
    c.total_spend,
    c.last_purchase_date,
    c.product_category
FROM 
    public.users u
JOIN 
    public.crm_data c ON u.user_id = c.user_id
WHERE 
    u.is_active = TRUE;
"""

# Read data from Redshift using the specified connection
redshift_data = glueContext.create_dynamic_frame.from_options(
    connection_type="redshift",
    connection_options={
        "redshiftTmpDir": args['TEMP_S3_DIR'],
        "useConnectionProperties": "true",
        "connectionName": args['REDSHIFT_CONNECTION_NAME'],
        "query": sql_query
    }
)

print(f"Data extracted from Redshift. Count: {redshift_data.count()}")
redshift_data.printSchema()

# Write the data to S3 in Parquet format for SageMaker
# Parquet is efficient for ML workloads
glueContext.write_dynamic_frame.from_options(
    frame=redshift_data,
    connection_type="s3",
    connection_options={
        "path": args['OUTPUT_S3_PATH'],
        "partitionKeys": []
    },
    format="parquet"
)

print(f"Successfully wrote data to {args['OUTPUT_S3_PATH']}")

job.commit()
