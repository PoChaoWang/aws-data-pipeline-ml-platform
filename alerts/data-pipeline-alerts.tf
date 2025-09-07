# This file defines CloudWatch Alarms for general data pipeline health.
# These alarms are broader and cover critical aspects of the overall data flow.

# Example S3 Error Bucket Alarm (for CSV processing failures):
# resource "aws_cloudwatch_metric_alarm" "s3_error_bucket_alarm" {
#   alarm_name          = "s3-csv-error-bucket-new-object"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "NumberOfObjects"
#   namespace           = "AWS/S3"
#   period              = "300" # 5 minutes
#   statistic           = "Sum"
#   threshold           = "0"   # Trigger if any new objects appear
#   alarm_description   = "Alarm when new objects are placed in the CSV error S3 bucket."
#   actions_enabled     = true
#
#   dimensions = {
#     BucketName = "your-csv-error-bucket-name" # Replace with your actual error bucket name
#   }
#
#   alarm_actions = [var.sns_topic_arn]
#   ok_actions    = [var.sns_topic_arn]
# }

# Example Step Functions Execution Failure Alarm:
# resource "aws_cloudwatch_metric_alarm" "step_function_failure_alarm" {
#   alarm_name          = "step-function-execution-failure"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "ExecutionsFailed"
#   namespace           = "AWS/StepFunctions"
#   period              = "300"
#   statistic           = "Sum"
#   threshold           = "0"
#   alarm_description   = "Alarm when a Step Function execution fails."
#   actions_enabled     = true
#
#   dimensions = {
#     StateMachineArn = "your-step-function-state-machine-arn" # Replace with actual ARN
#   }
#
#   alarm_actions = [var.sns_topic_arn]
#   ok_actions    = [var.sns_topic_arn]
# }

# Add more general data pipeline alarms here (e.g., DMS replication latency, Redshift cluster health)
