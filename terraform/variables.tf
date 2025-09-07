
variable "aws_region" {
  description = "The AWS region to deploy the resources in."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "The name of the project."
  type        = string
  default     = "aws-data-pipeline"
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "csv_bucket_name" {
  description = "The name of the S3 bucket for CSV files."
  type        = string
}

variable "csv_primary_key" {
  description = "The primary key for the CSV data table in Redshift."
  type        = string
}

variable "glue_scripts_bucket_name" {
  description = "The name of the S3 bucket for Glue scripts."
  type        = string
}

variable "redshift_db_name" {
  description = "The name of the Redshift database."
  type        = string
}

variable "redshift_master_username" {
  description = "The master username for the Redshift cluster."
  type        = string
}

variable "redshift_master_password" {
  description = "The master password for the Redshift cluster."
  type        = string
  sensitive   = true
}

# --- Oracle to Redshift Migration Variables ---

variable "dms_s3_staging_bucket_name" {
  description = "The name of the S3 bucket for DMS staging."
  type        = string
}

variable "oracle_credentials_json" {
  description = "A JSON string containing Oracle credentials (username, password)."
  type        = string
  sensitive   = true
}

variable "oracle_server_name" {
  description = "The server name or IP address of the Oracle database."
  type        = string
}

variable "oracle_port" {
  description = "The port for the Oracle database."
  type        = number
}

variable "oracle_db_name" {
  description = "The database name (SID) for the Oracle database."
  type        = string
}

variable "oracle_schema" {
  description = "The schema to migrate from Oracle."
  type        = string
}

# --- SageMaker User Segmentation Variables ---

variable "sagemaker_artifacts_bucket_name" {
  description = "The name of the S3 bucket for SageMaker model artifacts."
  type        = string
}

variable "sagemaker_training_image_uri" {
  description = "The ECR URI of the Docker image for SageMaker training (e.g., for KMeans)."
  type        = string
}

# --- Data Quality Check Variables ---

variable "alert_email" {
  description = "The email address for data quality alerts."
  type        = string
}

# --- Salesforce Integration Variables ---

variable "salesforce_credentials_json" {
  description = "A JSON string containing Salesforce credentials (username, password, security_token, etc.)."
  type        = string
  sensitive   = true
}
