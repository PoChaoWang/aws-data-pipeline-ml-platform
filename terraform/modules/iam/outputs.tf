
output "s3_uploader_policy_arn" {
  description = "The ARN of the S3 uploader policy."
  value       = aws_iam_policy.s3_uploader_policy.arn
}

output "developer_policy_arn" {
  description = "The ARN of the developer policy."
  value       = aws_iam_policy.developer_policy.arn
}
