output "oracle_secret_arn" {
  description = "The ARN of the Oracle DB secret"
  value       = aws_secretsmanager_secret.oracle_credentials.arn
}

output "salesforce_secret_arn" {
  description = "The ARN of the Salesforce API secret"
  value       = aws_secretsmanager_secret.salesforce_credentials.arn
}
