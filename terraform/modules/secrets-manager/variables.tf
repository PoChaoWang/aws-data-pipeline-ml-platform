variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "oracle_secret_json" {
  description = "JSON string containing Oracle DB credentials"
  type        = string
  sensitive   = true
}

variable "salesforce_secret_json" {
  description = "JSON string containing Salesforce API credentials"
  type        = string
  sensitive   = true
}
