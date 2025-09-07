
variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "csv_bucket_name" {
  description = "The name of the CSV S3 bucket."
  type        = string
}

variable "glue_csv_job_arn" {
  description = "The ARN of the CSV-to-Redshift Glue job."
  type        = string
}

variable "glue_oracle_job_arn" {
  description = "The ARN of the Oracle-to-Redshift Glue job."
  type        = string
}

variable "step_function_arn" {
  description = "The ARN of the Salesforce sync Step Function."
  type        = string
}
