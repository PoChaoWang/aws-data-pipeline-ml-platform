# terraform/environments/prod.tfvars
project_name    = "aws-data-pipeline"
environment     = "prod"
aws_region      = "us-east-1"
vpc_cidr        = "10.2.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# Redshift Configuration
redshift_master_username = "admin"
redshift_node_type      = "dc2.8xlarge"

# Notification
notification_email = "prod-alerts@company.com"

# Oracle Database
oracle_host     = "prod-oracle.company.com"
oracle_username = "prod_user"

# Salesforce
salesforce_client_id     = "prod_client_id"
salesforce_client_secret = "prod_client_secret"