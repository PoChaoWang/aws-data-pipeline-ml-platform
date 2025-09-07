variable "bucket_name" {
  description = "The name of the S3 bucket."
  type        = string
}

variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)."
  type        = string
}

variable "lambda_function_arn" {
  description = "The ARN of the Lambda function to be triggered."
  type        = string
  default     = ""
}

variable "enable_lifecycle_policy" {
  description = "Enable a lifecycle policy to archive and expire objects."
  type        = bool
  default     = false
}