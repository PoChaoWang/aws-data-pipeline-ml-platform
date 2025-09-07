# This file defines CloudWatch Alarms specifically for AWS Lambda functions.
# These alarms will monitor key Lambda metrics and trigger notifications via SNS.

# Example Lambda Error Rate Alarm:
# resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
#   alarm_name          = "lambda-function-error-rate"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "Errors"
#   namespace           = "AWS/Lambda"
#   period              = "300" # 5 minutes
#   statistic           = "Sum"
#   threshold           = "0"   # Trigger if any errors occur
#   alarm_description   = "Alarm when Lambda function errors occur."
#   actions_enabled     = true
#
#   dimensions = {
#     FunctionName = "your-lambda-function-name" # Replace with actual Lambda function name
#   }
#
#   alarm_actions = [var.sns_topic_arn] # Reference the SNS topic ARN passed from the main module
#   ok_actions    = [var.sns_topic_arn]
# }

# Add more Lambda-specific alarms here (e.g., Throttles, Duration, Invocations)
# Ensure to parameterize function names or use dynamic blocks if managing many functions.
