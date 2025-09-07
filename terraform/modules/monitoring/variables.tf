variable "dashboard_name" {
  description = "The name of the CloudWatch Dashboard."
  type        = string
  default     = "DataPipelineDashboard"
}

variable "sns_topic_arn" {
  description = "The ARN of the SNS topic to send alarms to."
  type        = string
}