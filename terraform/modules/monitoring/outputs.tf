output "dashboard_arn" {
  description = "The ARN of the CloudWatch Dashboard."
  value       = aws_cloudwatch_dashboard.main_dashboard.dashboard_arn
}