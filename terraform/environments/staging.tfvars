# terraform/environments/staging.tfvars
project_name    = "aws-data-pipeline"
environment     = "staging"
aws_region      = "us-east-1"
vpc_cidr        = "10.1.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# Redshift Configuration
redshift_master_username = "admin"
redshift_node_type      = "dc2.large"

# Notification
notification_email = "staging-team@company.com"

# Oracle Database
oracle_host     = "staging-oracle.company.com"
oracle_username = "staging_user"

# Salesforce
salesforce_client_id     = "staging_client_id"
salesforce_client_secret = "staging_client_secret"