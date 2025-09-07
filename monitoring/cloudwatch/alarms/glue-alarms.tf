# This file defines CloudWatch Alarms specifically for AWS Glue jobs.
# These alarms will monitor Glue job runs and trigger notifications via SNS.

# Example Glue Job Failure Alarm:
# resource "aws_cloudwatch_metric_alarm" "glue_job_failure_alarm" {
#   alarm_name          = "glue-job-failure-alarm"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "Failed"
#   namespace           = "AWS/Glue"
#   period              = "300" # 5 minutes
#   statistic           = "Sum"
#   threshold           = "0"   # Trigger if any job failures occur
#   alarm_description   = "Alarm when Glue job failures occur."
#   actions_enabled     = true
#
#   dimensions = {
#     JobName = "your-glue-job-name" # Replace with actual Glue job name
#   }
#
#   alarm_actions = [var.sns_topic_arn] # Reference the SNS topic ARN passed from the main module
#   ok_actions    = [var.sns_topic_arn]
# }

# Add more Glue-specific alarms here (e.g., Succeeded, Running, DPUHours)
# Ensure to parameterize job names or use dynamic blocks if managing many jobs.
