# --- S3 Uploader Policy ---
resource "aws_iam_policy" "s3_uploader_policy" {
  name        = "${var.project_name}-s3-uploader-policy"
  description = "Policy for users who can upload files to the CSV S3 bucket."

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:PutObject",
        Resource = "arn:aws:s3:::${var.csv_bucket_name}/*"
      }
    ]
  })
}

# --- Developer Policy ---
resource "aws_iam_policy" "developer_policy" {
  name        = "${var.project_name}-developer-policy"
  description = "Policy for developers to monitor and re-run pipeline components."

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid      = "MonitoringAccess",
        Effect   = "Allow",
        Action   = [
          "cloudwatch:Get*",
          "cloudwatch:List*",
          "logs:Get*",
          "logs:List*",
          "logs:Describe*"
        ],
        Resource = "*"
      },
      {
        Sid      = "RerunAccess",
        Effect   = "Allow",
        Action   = [
          "glue:StartJobRun",
          "states:StartExecution"
        ],
        Resource = [
          var.glue_csv_job_arn,
          var.glue_oracle_job_arn,
          var.step_function_arn
        ]
      }
    ]
  })
}
