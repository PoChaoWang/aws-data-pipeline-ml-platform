
provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-unique-name"
    key            = "aws-data-pipeline/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}

module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
}

module "s3_csv" {
  source                  = "./modules/s3"
  bucket_name             = var.csv_bucket_name
  project_name            = var.project_name
  environment             = var.environment
  lambda_function_arn     = module.lambda_csv_processor.lambda_function_arn
  enable_lifecycle_policy = true
}

module "lambda_csv_processor" {
  source          = "./modules/lambda"
  function_name   = "csv-processor"
  project_name    = var.project_name
  environment     = var.environment
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.8"
  s3_bucket_arn   = module.s3_csv.bucket_arn
  glue_job_arn    = module.glue_csv_to_redshift.glue_job_arn
  glue_job_name   = module.glue_csv_to_redshift.glue_job_name
  source_dir      = "../lambda/csv-processor"
  oracle_secret_arn = "" # Not directly used by this lambda
  salesforce_secret_arn = "" # Not directly used by this lambda
}

module "glue_csv_to_redshift" {
  source                   = "./modules/glue"
  job_name                 = "csv-to-redshift"
  project_name             = var.project_name
  environment              = var.environment
  s3_bucket_arn            = module.s3_csv.bucket_arn
  glue_scripts_bucket_name = var.glue_scripts_bucket_name
  s3_bucket_name           = module.s3_csv.bucket_name
  redshift_cluster_id      = module.redshift.cluster_id
  redshift_database        = module.redshift.database_name
  redshift_user            = var.redshift_master_username
  redshift_table           = "user_data"
  primary_key              = var.csv_primary_key
  oracle_secret_arn        = "" # Not directly used by this glue job
  salesforce_secret_arn    = "" # Not directly used by this glue job
}

module "redshift" {
  source             = "./modules/redshift"
  cluster_identifier = "${var.project_name}-redshift-cluster"
  project_name       = var.project_name
  environment        = var.environment
  db_name            = var.redshift_db_name
  master_username    = var.redshift_master_username
  master_password    = var.redshift_master_password
  vpc_id             = module.vpc.vpc_id
  iam_role_arn       = module.glue_csv_to_redshift.glue_role_arn # Note: You might need a specific IAM role for Redshift Spectrum, etc.
}

# --- Oracle to Redshift Migration ---

module "s3_dms_staging" {
  source              = "./modules/s3"
  bucket_name         = var.dms_s3_staging_bucket_name
  project_name        = var.project_name
  environment         = var.environment
  lambda_function_arn = "" # No Lambda trigger for this bucket
}

resource "aws_iam_role" "dms_s3_role" {
  name = "${var.project_name}-dms-s3-access-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
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
}

resource "aws_iam_policy" "dms_s3_policy" {
  name        = "${var.project_name}-dms-s3-access-policy"
  description = "Policy for DMS to access the S3 staging bucket."

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          module.s3_dms_staging.bucket_arn,
          "${module.s3_dms_staging.bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dms_s3_policy_attach" {
  role       = aws_iam_role.dms_s3_role.name
  policy_arn = aws_iam_policy.dms_s3_policy.arn
}

module "oracle_credentials" {
  source             = "./modules/secrets-manager"
  environment        = var.environment # Pass environment variable
  oracle_secret_json = var.oracle_credentials_json # This variable will be passed from CI/CD
  salesforce_secret_json = "" # Placeholder, as this module call is specifically for Oracle
}

module "dms" {
  source                     = "./modules/dms"
  project_name               = var.project_name
  replication_instance_class = "dms.t3.medium"
  
  oracle_secret_arn          = module.oracle_credentials.oracle_secret_arn # Use ARN from secrets-manager module
  oracle_schema              = var.oracle_schema # Keep this

  s3_staging_bucket_name     = module.s3_dms_staging.bucket_name
  dms_s3_role_arn            = aws_iam_role.dms_s3_role.arn
}

module "glue_oracle_to_redshift" {
  source                   = "./modules/glue"
  job_name                 = "oracle-to-redshift"
  project_name             = var.project_name
  environment              = var.environment
  s3_bucket_arn            = module.s3_dms_staging.bucket_arn
  glue_scripts_bucket_name = var.glue_scripts_bucket_name
  s3_bucket_name           = module.s3_dms_staging.bucket_name
  redshift_cluster_id      = module.redshift.cluster_id
  redshift_database        = module.redshift.database_name
  redshift_user            = var.redshift_master_username
  redshift_table           = "crm_data" # Example table name
  oracle_secret_arn        = module.oracle_credentials.oracle_secret_arn # Pass Oracle secret ARN
  salesforce_secret_arn    = "" # Not directly used by this glue job
}

# --- SageMaker User Segmentation ---

module "s3_sagemaker_artifacts" {
  source              = "./modules/s3"
  bucket_name         = var.sagemaker_artifacts_bucket_name
  project_name        = var.project_name
  environment         = var.environment
  lambda_function_arn = "" # No Lambda trigger
}

module "sagemaker" {
  source                      = "./modules/sagemaker"
  project_name                = var.project_name
  notebook_instance_type      = "ml.t3.medium"
  inference_instance_type     = "ml.t2.medium"
  training_image_uri          = var.sagemaker_training_image_uri
  s3_model_artifacts_bucket   = module.s3_sagemaker_artifacts.bucket_name
  model_artifacts_path        = "user-segmentation/model.tar.gz"
}

# --- Data Quality Check & Failure Notification ---

module "sns_notifications" {
  source         = "./modules/sns"
  topic_name     = "${var.project_name}-data-pipeline-alerts"
  email_endpoint = var.alert_email
}

# Rule for SUCCESSFUL jobs -> Trigger Lambda for Data Quality Check
resource "aws_cloudwatch_event_rule" "glue_job_success_rule" {
  name        = "${var.project_name}-glue-job-success-rule"
  description = "Trigger data quality check on Glue job success"

  event_pattern = jsonencode({
    source      = ["aws.glue"],
    "detail-type" = ["Glue Job State Change"],
    detail = {
      jobName = [module.glue_csv_to_redshift.job_name, module.glue_oracle_to_redshift.job_name],
      state   = ["SUCCEEDED"]
    }
  })
}

module "lambda_data_quality_checker" {
  source          = "./modules/lambda"
  function_name   = "data-quality-checker"
  project_name    = var.project_name
  environment     = var.environment
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.8"
  source_dir      = "../lambda/data-quality-checker"
  oracle_secret_arn = "" # Not directly used by this lambda
  salesforce_secret_arn = "" # Not directly used by this lambda
  environment_variables = {
    SNS_TOPIC_ARN = module.sns_notifications.topic_arn
    REDSHIFT_CLUSTER_ID = module.redshift.cluster_id
    REDSHIFT_DATABASE = module.redshift.database_name
    REDSHIFT_USER = var.redshift_master_username
  }
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.glue_job_success_rule.name
  target_id = "TriggerDataQualityLambda"
  arn       = module.lambda_data_quality_checker.lambda_function_arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_data_quality_checker.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.glue_job_success_rule.arn
}

# Rule for FAILED jobs -> Trigger SNS notification directly
resource "aws_cloudwatch_event_rule" "glue_job_failure_rule" {
  name        = "${var.project_name}-glue-job-failure-rule"
  description = "Trigger SNS notification on Glue job failure"

  event_pattern = jsonencode({
    source      = ["aws.glue"],
    "detail-type" = ["Glue Job State Change"],
    detail = {
      jobName = [module.glue_csv_to_redshift.job_name, module.glue_oracle_to_redshift.job_name],
      state   = ["FAILED", "TIMEOUT", "STOPPED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.glue_job_failure_rule.name
  target_id = "TriggerSNSNotification"
  arn       = module.sns_notifications.topic_arn
  
  # This transforms the event into a more readable message
  input_transformer {
    input_paths = {
      "jobName" = "$.detail.jobName",
      "state" = "$.detail.state",
      "errorMessage" = "$.detail.message"
    }
    input_template = "A data pipeline job has failed.\n\nJob Name: <jobName>\nEnd State: <state>\nError Message: <errorMessage>\n\nPlease check the Glue console and the S3 error directory for more details."
  }
}


# --- Salesforce Integration ---

module "salesforce_credentials" {
  source                 = "./modules/secrets-manager"
  environment            = var.environment # Pass environment variable
  oracle_secret_json     = "" # Placeholder, as this module call is specifically for Salesforce
  salesforce_secret_json = var.salesforce_credentials_json # This variable will be passed from CI/CD
}

module "lambda_salesforce_integration" {
  source        = "./modules/lambda"
  function_name = "salesforce-integration"
  project_name  = var.project_name
  environment   = var.environment
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  source_dir    = "../lambda/salesforce-integration"
  oracle_secret_arn = "" # Not directly used by this lambda
  salesforce_secret_arn = module.salesforce_credentials.salesforce_secret_arn # Pass the correct ARN
  environment_variables = {
    SALESFORCE_SECRET_ARN = module.salesforce_credentials.salesforce_secret_arn # Pass the correct ARN
  }
}

module "step_function_salesforce_sync" {
  source                 = "./modules/stepfunctions"
  state_machine_name     = "salesforce-sync-pipeline"
  project_name           = var.project_name
  state_machine_definition = file("${path.module}/../step-functions/salesforce-sync-pipeline.json")
}

# --- Monitoring ---

module "monitoring" {
  source         = "./modules/monitoring"
  project_name   = var.project_name
  dashboard_body = file("${path.module}/../monitoring/cloudwatch/dashboards/main-dashboard.json")
}

# --- Human Access IAM Policies ---

module "iam_policies" {
  source = "./modules/iam"
  project_name = var.project_name

  csv_bucket_name = module.s3_csv.bucket_name

  glue_csv_job_arn    = module.glue_csv_to_redshift.glue_job_arn
  glue_oracle_job_arn = module.glue_oracle_to_redshift.glue_job_arn
  step_function_arn   = module.step_function_salesforce_sync.state_machine_arn
}
