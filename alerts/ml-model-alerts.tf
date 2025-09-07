# This file defines CloudWatch Alarms specifically for Machine Learning models and SageMaker.
# These alarms monitor model performance, endpoint health, and training job status.

# Example SageMaker Endpoint Invocations Error Alarm:
# resource "aws_cloudwatch_metric_alarm" "sagemaker_endpoint_error_alarm" {
#   alarm_name          = "sagemaker-endpoint-invocation-error"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "InvocationErrors"
#   namespace           = "AWS/SageMaker"
#   period              = "300"
#   statistic           = "Sum"
#   threshold           = "0"
#   alarm_description   = "Alarm when SageMaker endpoint invocation errors occur."
#   actions_enabled     = true
#
#   dimensions = {
#     EndpointName = "your-sagemaker-endpoint-name" # Replace with actual endpoint name
#   }
#
#   alarm_actions = [var.sns_topic_arn]
#   ok_actions    = [var.sns_topic_arn]
# }

# Example SageMaker Training Job Failure Alarm:
# resource "aws_cloudwatch_metric_alarm" "sagemaker_training_failure_alarm" {
#   alarm_name          = "sagemaker-training-job-failure"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "TrainingJobStatus" # Custom metric if you push job status
#   namespace           = "AWS/SageMaker"
#   period              = "300"
#   statistic           = "Maximum"
#   threshold           = "0" # Assuming 0 for failed, 1 for success
#   alarm_description   = "Alarm when a SageMaker training job fails."
#   actions_enabled     = true
#
#   dimensions = {
#     JobName = "your-sagemaker-training-job-name" # Replace with actual job name
#   }
#
#   alarm_actions = [var.sns_topic_arn]
#   ok_actions    = [var.sns_topic_arn]
# }

# Add more ML-specific alarms here (e.g., model quality metrics, data drift)
