resource "aws_sns_topic" "data_pipeline_alerts" {
  name = var.sns_topic_name
}

resource "aws_sns_topic_subscription" "data_pipeline_email_subscription" {
  topic_arn = aws_sns_topic.data_pipeline_alerts.arn
  protocol  = "email"
  endpoint  = var.sns_subscription_email
  # You might want to add more subscriptions here (e.g., for Slack, PagerDuty)
}

output "sns_topic_arn" {
  description = "The ARN of the SNS topic for data pipeline alerts."
  value       = aws_sns_topic.data_pipeline_alerts.arn
}