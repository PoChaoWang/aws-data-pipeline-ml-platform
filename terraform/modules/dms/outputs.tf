
output "replication_instance_arn" {
  description = "The ARN of the DMS replication instance."
  value       = aws_dms_replication_instance.default.replication_instance_arn
}

output "source_endpoint_arn" {
  description = "The ARN of the DMS source endpoint."
  value       = aws_dms_endpoint.source.endpoint_arn
}

output "target_endpoint_arn" {
  description = "The ARN of the DMS target endpoint."
  value       = aws_dms_endpoint.target.endpoint_arn
}

output "replication_task_arn" {
  description = "The ARN of the DMS replication task."
  value       = aws_dms_replication_task.oracle_to_s3.replication_task_arn
}

output "dms_secrets_manager_role_arn" {
  description = "The ARN of the IAM role for DMS to access Secrets Manager."
  value       = aws_iam_role.dms_secrets_manager_role.arn
}
