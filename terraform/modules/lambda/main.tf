
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}-${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.project_name}-${var.function_name}-policy"
  description = "Policy for Lambda function to access various services."

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid      = "S3Access",
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:ListBucket"],
        Resource = compact([var.s3_bucket_arn, var.s3_bucket_arn != "" ? "${var.s3_bucket_arn}/*" : ""])
      },
      {
        Sid      = "GlueAccess",
        Effect   = "Allow",
        Action   = "glue:StartJobRun",
        Resource = compact([var.glue_job_arn])
      },
      {
        Sid      = "SNSAccess",
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = "*" # NOTE: Should be restricted to a specific SNS topic ARN
      },
      {
        Sid      = "RedshiftDataAccess",
        Effect   = "Allow",
        Action   = ["redshift-data:ExecuteStatement", "redshift:DescribeClusters"],
        Resource = "*" # NOTE: Should be restricted to specific Redshift resources
      },
      {
        Sid      = "SecretsManagerAccess",
        Effect   = "Allow",
        Action   = "secretsmanager:GetSecretValue",
        Resource = [var.oracle_secret_arn, var.salesforce_secret_arn] # Restrict to specific secrets
      },
      {
        Sid      = "Logging",
        Effect   = "Allow",
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "default_lambda" {
  function_name = var.function_name
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = merge(
      var.glue_job_name != "" ? { GLUE_JOB_NAME = var.glue_job_name } : {},
      var.salesforce_secret_arn != "" ? { SALESFORCE_SECRET_ARN = var.salesforce_secret_arn } : {},
      var.environment_variables
    )
  }

  tags = {
    Name        = "${var.project_name}-${var.function_name}"
    Environment = var.environment
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/${var.function_name}.zip"
}
