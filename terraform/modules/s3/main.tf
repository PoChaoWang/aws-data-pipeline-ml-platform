resource "aws_s3_bucket" "csv_bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = "${var.project_name}-csv-bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  count = var.lambda_function_arn != "" ? 1 : 0

  bucket = aws_s3_bucket.csv_bucket.id

  lambda_function {
    lambda_function_arn = var.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "csv/"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "default" {
  count = var.enable_lifecycle_policy ? 1 : 0

  bucket = aws_s3_bucket.csv_bucket.id

  rule {
    id      = "archive-and-expire"
    status  = "Enabled"

    # This filter can be adjusted if you have different data types in the same bucket
    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "GLACIER_IR" # Glacier Instant Retrieval is cost-effective for long-term storage with occasional instant access.
    }

    expiration {
      days = 730 # 2 years
    }

    noncurrent_version_transition {
        noncurrent_days = 30
        storage_class   = "GLACIER_IR"
    }

    noncurrent_version_expiration {
        noncurrent_days = 730
    }
  }
}