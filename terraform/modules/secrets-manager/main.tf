resource "aws_secretsmanager_secret" "oracle_credentials" {
  name        = "${var.environment}/oracle/credentials"
  description = "Oracle DB credentials for migration"

  tags = {
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "oracle_credentials_version" {
  secret_id     = aws_secretsmanager_secret.oracle_credentials.id
  secret_string = var.oracle_secret_json
}

resource "aws_secretsmanager_secret" "salesforce_credentials" {
  name        = "${var.environment}/salesforce/credentials"
  description = "Salesforce API credentials for integration"

  tags = {
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "salesforce_credentials_version" {
  secret_id     = aws_secretsmanager_secret.salesforce_credentials.id
  secret_string = var.salesforce_secret_json
}
