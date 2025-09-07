
resource "aws_iam_role" "glue_role" {
  name = "${var.project_name}-${var.job_name}-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "glue_policy" {
  name        = "${var.project_name}-${var.job_name}-policy"
  description = "Policy for Glue job to access S3 and Redshift."

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Effect   = "Allow",
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      },
      {
        Action   = [
          "redshift:DescribeClusters",
          "redshift-data:ExecuteStatement"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Sid      = "SecretsManagerAccess",
        Effect   = "Allow",
        Action   = "secretsmanager:GetSecretValue",
        Resource = [var.oracle_secret_arn, var.salesforce_secret_arn] # Restrict to specific secrets
      },
      {
        Action   = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_policy_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_policy.arn
}

resource "aws_glue_job" "csv_to_redshift" {
  name     = var.job_name
  role_arn = aws_iam_role.glue_role.arn

  command {
    script_location = "s3://${var.glue_scripts_bucket_name}/${var.job_name}.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-bookmark-option"      = "job-bookmark-enable",
    "--enable-metrics"           = "",
    "--S3_BUCKET_NAME"           = var.s3_bucket_name,
    "--REDSHIFT_CLUSTER_ID"      = var.redshift_cluster_id,
    "--REDSHIFT_DATABASE"        = var.redshift_database,
    "--REDSHIFT_USER"            = var.redshift_user,
    "--REDSHIFT_TABLE"           = var.redshift_table,
    "--PRIMARY_KEY"              = var.primary_key
  }

  tags = {
    Name        = "${var.project_name}-${var.job_name}"
    Environment = var.environment
  }
}
