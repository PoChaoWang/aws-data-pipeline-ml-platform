
variable "cluster_identifier" {
  description = "The identifier for the Redshift cluster."
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

variable "db_name" {
  description = "The name of the Redshift database."
  type        = string
}

variable "master_username" {
  description = "The master username for the Redshift cluster."
  type        = string
}

variable "master_password" {
  description = "The master password for the Redshift cluster."
  type        = string
  sensitive   = true
}

variable "node_type" {
  description = "The node type for the Redshift cluster."
  type        = string
  default     = "dc2.large"
}

variable "vpc_id" {
  description = "The ID of the VPC where the Redshift cluster will be created."
  type        = string
}

variable "iam_role_arn" {
  description = "The ARN of the IAM role to be associated with the Redshift cluster."
  type        = string
}
