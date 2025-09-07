resource "aws_cloudwatch_dashboard" "main_dashboard" {
  dashboard_name = var.dashboard_name
  dashboard_body = file("${path.module}/../../monitoring/cloudwatch/dashboards/main-dashboard.json")
}

# --- CloudWatch Alarms --- 
# The following sections are placeholders for integrating the alarm definitions
# from the separate .tf files you requested. In a real-world scenario, you would
# either define these alarms directly here, or use Terraform modules/for_each
# to manage them dynamically.

# Example: Including Lambda Alarms (assuming lambda-alarms.tf defines resources)
# module "lambda_alarms" {
#   source = "./monitoring/cloudwatch/alarms/lambda-alarms.tf" # This is not how modules work directly
#   # Instead, you would define the alarms directly in this main.tf or a sub-module
#   # For example:
#   # resource "aws_cloudwatch_metric_alarm" "example_lambda_error" {
#   #   # ... alarm configuration ...
#   #   alarm_actions = [var.sns_topic_arn]
#   # }
# }

# You would define your specific alarms here, referencing the SNS topic ARN.
# For instance, alarms defined in:
# - monitoring/cloudwatch/alarms/lambda-alarms.tf
# - monitoring/cloudwatch/alarms/glue-alarms.tf
# - alerts/data-pipeline-alerts.tf
# - alerts/ml-model-alerts.tf
# would be instantiated as `resource "aws_cloudwatch_metric_alarm"` blocks within this module,
# passing `var.sns_topic_arn` to their `alarm_actions` and `ok_actions`.

# Example of how an alarm might look, referencing the SNS topic:
# resource "aws_cloudwatch_metric_alarm" "csv_processor_errors" {
#   alarm_name          = "csv-processor-lambda-errors"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "Errors"
#   namespace           = "AWS/Lambda"
#   period              = "300"
#   statistic           = "Sum"
#   threshold           = "0"
#   alarm_description   = "Alarm when CSV processor Lambda encounters errors."
#   actions_enabled     = true
#
#   dimensions = {
#     FunctionName = "csv-processor"
#   }
#
#   alarm_actions = [var.sns_topic_arn]
#   ok_actions    = [var.sns_topic_arn]
# }