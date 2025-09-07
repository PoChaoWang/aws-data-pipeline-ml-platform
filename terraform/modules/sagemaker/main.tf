
resource "aws_iam_role" "sagemaker_role" {
  name = "${var.project_name}-sagemaker-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "sagemaker_policy" {
  name        = "${var.project_name}-sagemaker-policy"
  description = "Policy for SageMaker to access S3, etc."

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action   = ["s3:*"],
        Effect   = "Allow",
        Resource = "*" # For simplicity. Should be restricted to specific buckets.
      },
      {
        Action   = ["cloudwatch:PutMetricData"],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action   = ["ecr:GetAuthorizationToken", "ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage"],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_policy_attach" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = aws_iam_policy.sagemaker_policy.arn
}

resource "aws_sagemaker_notebook_instance" "default" {
  name          = "${var.project_name}-notebook"
  role_arn      = aws_iam_role.sagemaker_role.arn
  instance_type = var.notebook_instance_type

  tags = {
    Name = "${var.project_name}-notebook"
  }
}

resource "aws_sagemaker_model" "user_segmentation" {
  name               = "${var.project_name}-user-segmentation-model"
  execution_role_arn = aws_iam_role.sagemaker_role.arn

  primary_container {
    image = var.training_image_uri
    model_data_url = "s3://${var.s3_model_artifacts_bucket}/${var.model_artifacts_path}"
  }

  tags = {
    Name = "${var.project_name}-user-segmentation-model"
  }
}

resource "aws_sagemaker_endpoint_configuration" "default" {
  name = "${var.project_name}-endpoint-config"

  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.user_segmentation.name
    initial_instance_count = 1
    instance_type          = var.inference_instance_type
  }

  tags = {
    Name = "${var.project_name}-endpoint-config"
  }
}

resource "aws_sagemaker_endpoint" "default" {
  name                 = "${var.project_name}-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.default.name

  tags = {
    Name = "${var.project_name}-endpoint"
  }
}
