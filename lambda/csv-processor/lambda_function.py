import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

glue = boto3.client('glue')

def lambda_handler(event, context):
    """
    Triggers a Glue job to process a CSV file uploaded to S3.
    """
    try:
        # Get the bucket name and key from the S3 event
        bucket_name = event['Records'][0]['s3']['bucket']['name']
        s3_key = event['Records'][0]['s3']['object']['key']

        glue_job_name = os.environ['GLUE_JOB_NAME']

        logger.info(f"Starting Glue job '{glue_job_name}' for file 's3://{bucket_name}/{s3_key}'")

        # Start the Glue job
        response = glue.start_job_run(
            JobName=glue_job_name,
            Arguments={
                '--S3_SOURCE_PATH': f's3://{bucket_name}/{s3_key}'
            }
        )

        logger.info(f"Successfully started Glue job with run ID: {response['JobRunId']}")

        return {
            'statusCode': 200,
            'body': f"Successfully started Glue job '{glue_job_name}'"
        }

    except Exception as e:
        logger.error(f"Error starting Glue job: {e}")
        raise e