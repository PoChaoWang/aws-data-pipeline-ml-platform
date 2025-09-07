
resource "aws_dms_replication_instance" "default" {
  replication_instance_id   = "${var.project_name}-dms-instance"
  replication_instance_class = var.replication_instance_class
  allocated_storage          = 20

  tags = {
    Name = "${var.project_name}-dms-instance"
  }
}

resource "aws_dms_endpoint" "source" {
  endpoint_id   = "${var.project_name}-oracle-source-endpoint"
  endpoint_type = "source"
  engine_name   = "oracle"

  # Use Secrets Manager for credentials
  secrets_manager_secret_id     = var.oracle_secret_arn # This is the ARN of the secret
  secrets_manager_access_role_arn = aws_iam_role.dms_secrets_manager_role.arn # DMS role to access Secrets Manager

  # Extra connection attributes can be added here if needed
  # extra_connection_attributes = "..."

  tags = {
    Name = "${var.project_name}-oracle-source-endpoint"
  }
}

resource "aws_dms_endpoint" "target" {
  endpoint_id   = "${var.project_name}-s3-target-endpoint"
  endpoint_type = "target"
  engine_name   = "s3"

  s3_settings {
    bucket_name = var.s3_staging_bucket_name
    service_access_role_arn = var.dms_s3_role_arn
  }

  tags = {
    Name = "${var.project_name}-s3-target-endpoint"
  }
}

resource "aws_dms_replication_task" "oracle_to_s3" {
  migration_type           = "full-load-and-cdc"
  replication_task_id      = "${var.project_name}-oracle-to-s3-task"
  replication_instance_arn = aws_dms_replication_instance.default.replication_instance_arn
  source_endpoint_arn      = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.target.endpoint_arn

  table_mappings = jsonencode({
    rules = [
      {
        "rule-type" = "selection",
        "rule-id" = "1",
        "rule-name" = "SelectAll",
        "object-locator" = {
          "schema-name" = var.oracle_schema,
          "table-name" = "%"
        },
        "rule-action" = "include"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-oracle-to-s3-task"
  }
}

# IAM Role for DMS to access Secrets Manager
resource "aws_iam_role" "dms_secrets_manager_role" {
  name = "${var.project_name}-dms-secrets-manager-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "dms.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-dms-secrets-manager-role"
  }
}

resource "aws_iam_policy" "dms_secrets_manager_policy" {
  name        = "${var.project_name}-dms-secrets-manager-policy"
  description = "Policy for DMS to access Secrets Manager for Oracle credentials."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "secretsmanager:GetSecretValue",
        Resource = var.oracle_secret_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dms_secrets_manager_policy_attach" {
  role       = aws_iam_role.dms_secrets_manager_role.name
  policy_arn = aws_iam_policy.dms_secrets_manager_policy.arn
}
