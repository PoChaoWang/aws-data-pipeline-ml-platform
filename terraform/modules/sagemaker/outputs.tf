
output "notebook_instance_name" {
  description = "The name of the SageMaker notebook instance."
  value       = aws_sagemaker_notebook_instance.default.name
}

output "endpoint_name" {
  description = "The name of the SageMaker endpoint."
  value       = aws_sagemaker_endpoint.default.name
}
