
variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "replication_instance_class" {
  description = "The replication instance class for DMS."
  type        = string
  default     = "dms.t2.medium"
}

variable "oracle_secret_arn" {
  description = "The ARN of the Oracle DB secret in Secrets Manager."
  type        = string
}

variable "oracle_schema" {
  description = "The schema to migrate from Oracle."
  type        = string
}

variable "s3_staging_bucket_name" {
  description = "The name of the S3 bucket to use as a staging area."
  type        = string
}

variable "dms_s3_role_arn" {
  description = "The ARN of the IAM role for DMS to access S3."
  type        = string
}
