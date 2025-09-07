import boto3
import pandas as pd

def detect_schema_from_s3_csv(bucket, key):
    """Detects the schema of a CSV file in S3 using pandas."""
    try:
        s3 = boto3.client('s3')
        obj = s3.get_object(Bucket=bucket, Key=key)
        df = pd.read_csv(obj['Body'])
        
        schema = []
        for column, dtype in df.dtypes.items():
            schema.append({'name': column, 'type': str(dtype)})
            
        return schema
    except Exception as e:
        print(f"Error detecting schema: {e}")
        raise e