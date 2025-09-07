# terraform/outputs.tf
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "s3_data_lake_bucket" {
  description = "Name of the S3 data lake bucket"
  value       = module.s3.data_lake_bucket_name
}

output "redshift_cluster_endpoint" {
  description = "Redshift cluster endpoint"
  value       = module.redshift.cluster_endpoint
  sensitive   = true
}

output "redshift_cluster_id" {
  description = "Redshift cluster identifier"
  value       = module.redshift.cluster_id
}

output "glue_database_name" {
  description = "Name of the Glue database"
  value       = module.glue.database_name
}

output "lambda_function_names" {
  description = "Names of Lambda functions"
  value       = module.lambda.function_names
}

output "sagemaker_notebook_instance" {
  description = "SageMaker notebook instance name"
  value       = module.sagemaker.notebook_instance_name
}

output "step_function_arns" {
  description = "ARNs of Step Function state machines"
  value       = module.stepfunctions.state_machine_arns
}

output "monitoring_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = module.monitoring.dashboard_url
}
