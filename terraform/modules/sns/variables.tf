variable "sns_topic_name" {
  description = "The name of the SNS topic."
  type        = string
  default     = "data-pipeline-alerts"
}

variable "sns_subscription_email" {
  description = "The email address to subscribe to the SNS topic for alerts."
  type        = string
  # You should provide a default or make this required in your environment tfvars
}