
variable "job_name" {
  description = "The name of the Glue job."
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

variable "s3_bucket_arn" {
  description = "The ARN of the S3 bucket."
  type        = string
}

variable "glue_scripts_bucket_name" {
  description = "The name of the S3 bucket for Glue scripts."
  type        = string
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket where CSVs are located."
  type        = string
}

variable "redshift_cluster_id" {
  description = "The ID of the Redshift cluster."
  type        = string
}

variable "redshift_database" {
  description = "The name of the Redshift database."
  type        = string
}

variable "redshift_user" {
  description = "The user for the Redshift database."
  type        = string
}

variable "redshift_table" {
  description = "The table name in Redshift."
  type        = string
}

variable "primary_key" {
  description = "The primary key of the target Redshift table."
  type        = string
  default     = ""
}

variable "oracle_secret_arn" {
  description = "The ARN of the Oracle DB secret for Glue to access."
  type        = string
}

variable "salesforce_secret_arn" {
  description = "The ARN of the Salesforce API secret for Glue to access."
  type        = string
}

