import json
import boto3
import csv
from io import StringIO

# Import data quality rules
# Note: This import assumes the rules are in the same package or accessible
from rules.quality_rules import get_python_rules

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    print("Lambda function invoked with event:", event)
    
    s3_path = event.get('s3_path')
    if not s3_path:
        return {
            'status': 'FAILED',
            'errors_found': True,
            'details': [{'error_type': 'MISSING_S3_PATH', 'description': 'No S3 path provided in event.'}]
        }

    # Parse S3 path
    # Assuming s3_path is like 's3://your-bucket/your-key/file.csv'
    try:
        bucket_name = s3_path.split('//')[1].split('/')[0]
        key = '/'.join(s3_path.split('//')[1].split('/')[1:])
    except IndexError:
        return {
            'status': 'FAILED',
            'errors_found': True,
            'details': [{'error_type': 'INVALID_S3_PATH_FORMAT', 'description': f'Invalid S3 path format: {s3_path}'}]
        }

    all_python_errors = []
    
    try:
        # Read data from S3
        response = s3_client.get_object(Bucket=bucket_name, Key=key)
        csv_content = response['Body'].read().decode('utf-8')
        
        # Process CSV content
        # Assuming CSV has a header row
        reader = csv.DictReader(StringIO(csv_content))
        records = list(reader) # Convert to list of dictionaries for easier processing
        
        print(f"Successfully read {len(records)} records from {s3_path}")

        # Get all Python data quality rules
        python_rules = get_python_rules()

        # Apply each Python rule to each record
        for i, record in enumerate(records):
            # Add a record identifier for error reporting if not present
            record_identifier = record.get('id', f'row_{i+1}') # Use 'id' or row number
            
            for rule_func in python_rules:
                error = rule_func(record)
                if error:
                    # Augment error with record identifier and source info
                    error['record_identifier'] = record_identifier
                    error['source_s3_path'] = s3_path
                    error['rule_name'] = rule_func.__name__ # Add rule function name
                    all_python_errors.append(error)
        
        if all_python_errors:
            print(f"Found {len(all_python_errors)} Python data quality issues.")
            return {
                'status': 'FAILED',
                'errors_found': True,
                'details': all_python_errors
            }
        else:
            print("No Python data quality issues found.")
            return {
                'status': 'SUCCESS',
                'errors_found': False,
                'details': []
            }

    except Exception as e:
        print(f"Error processing data from S3 or applying Python rules: {e}")
        return {
            'status': 'FAILED',
            'errors_found': True,
            'details': [{'error_type': 'LAMBDA_PROCESSING_ERROR', 'description': str(e), 'source_s3_path': s3_path}]
        }