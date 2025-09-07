import boto3

s3 = boto3.client('s3')

def get_s3_object_metadata(bucket, key):
    """Gets metadata for an S3 object."""
    try:
        response = s3.head_object(Bucket=bucket, Key=key)
        return response['Metadata']
    except Exception as e:
        print(f"Error getting S3 object metadata: {e}")
        raise e