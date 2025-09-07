
import os
import json
import boto3
import pandas as pd
from salesforce.client import SalesforceClient

s3 = boto3.client('s3')

def get_secret(secret_name_or_arn, region_name="us-east-1"):
    """
    從 AWS Secrets Manager 檢索秘密。
    """
    client = boto3.client('secretsmanager', region_name=region_name)
    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name_or_arn
        )
    except Exception as e:
        print(f"Error retrieving secret: {e}")
        raise e

    if 'SecretString' in get_secret_value_response:
        return json.loads(get_secret_value_response['SecretString'])
    else:
        raise ValueError("Secret is not a string type.")

def lambda_handler(event, context):
    """
    Reads SageMaker batch transform output and updates Salesforce.
    """
    print("Received event:", json.dumps(event))

    # 1. Get SageMaker output location from the event
    s3_output_path = event.get('s3_output_path')
    if not s3_output_path:
        raise ValueError("Missing 's3_output_path' in the event payload.")

    # 2. Read prediction results from S3
    # The output file name is often the input file name with .out appended.
    # This might need adjustment based on your SageMaker job's configuration.
    bucket, key = s3_output_path.replace("s3://", "").split("/", 1)
    # Assuming the output is a single file. You might need to list objects in the prefix.
    # This is a simplification.
    obj = s3.get_object(Bucket=bucket, Key=f"{key}/your_input_file.csv.out") 
    predictions = pd.read_csv(obj['Body'], header=None)
    # TODO: You need to map predictions back to user identifiers (e.g., emails)
    # This requires the original data to be joined with the predictions.

    # 3. Get Salesforce credentials from Secrets Manager
    salesforce_secret_arn = os.environ.get('SALESFORCE_SECRET_ARN')
    if not salesforce_secret_arn:
        raise ValueError("SALESFORCE_SECRET_ARN environment variable not set.")

    sf_creds = get_secret(salesforce_secret_arn)

    # 4. Initialize Salesforce client
    sf_client = SalesforceClient(
        username=sf_creds['username'],
        password=sf_creds['password'],
        security_token=sf_creds['security_token']
    )

    if not sf_client.is_connected():
        raise ConnectionError("Failed to connect to Salesforce.")

    # 5. Iterate and update Salesforce
    # This is a placeholder loop. You need to adapt it to your data.
    # for index, row in predictions.iterrows():
    #     email = row['email'] # Assuming you have an 'email' column
    #     segment = row['prediction'] # Assuming you have a 'prediction' column
    #     sf_client.update_contact_segment(email, segment)

    print("Salesforce sync complete.")

    return {
        'statusCode': 200,
        'body': json.dumps('Salesforce sync complete.')
    }
