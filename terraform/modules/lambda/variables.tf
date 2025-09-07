variable "function_name" {
  description = "The name of the Lambda function."
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

variable "handler" {
  description = "The handler for the Lambda function."
  type        = string
}

variable "runtime" {
  description = "The runtime for the Lambda function."
  type        = string
}

variable "timeout" {
  description = "The timeout for the Lambda function."
  type        = number
  default     = 30
}

variable "s3_bucket_arn" {
  description = "The ARN of the S3 bucket."
  type        = string
  default     = ""
}

variable "glue_job_arn" {
  description = "The ARN of the Glue job."
  type        = string
  default     = ""
}

variable "glue_job_name" {
  description = "The name of the Glue job."
  type        = string
  default     = ""
}

variable "source_dir" {
  description = "The source directory of the Lambda function code."
  type        = string
}

variable "environment_variables" {
  description = "A map of environment variables for the Lambda function."
  type        = map(string)
  default     = {}
}

variable "oracle_secret_arn" {
  description = "The ARN of the Oracle DB secret for Lambda to access."
  type        = string
}

variable "salesforce_secret_arn" {
  description = "The ARN of the Salesforce API secret for Lambda to access."
  type        = string
}
