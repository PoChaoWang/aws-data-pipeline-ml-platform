aws_region                 = "us-east-1"
project_name               = "aws-data-pipeline-dev"
environment                = "dev"
csv_bucket_name            = "my-awesome-project-csv-bucket-dev"
csv_primary_key            = "user_id" # 請根據您的 CSV 檔案更換主鍵欄位
glue_scripts_bucket_name   = "my-awesome-project-glue-scripts-dev"
redshift_db_name           = "devdb"
redshift_master_username   = "devuser"
redshift_master_password   = "MustBeChanged1"

# --- Oracle to Redshift Migration Variables ---
# 請在下方填寫您自己的數值
dms_s3_staging_bucket_name = "my-awesome-project-dms-staging-dev"

# 請注意：建議使用更安全的方式來管理密鑰，例如從 CI/CD 環境變數中讀取
oracle_credentials_json    = "{\"username\":\"oracle_user\",\"password\":\"MustBeChanged2\"}"
oracle_server_name         = "oracle.example.com" # 請替換成您的 Oracle 主機名稱或 IP
oracle_port                = 1521                 # 請替換成您的 Oracle 連接埠
oracle_db_name             = "ORCL"                 # 請替換成您的 Oracle SID
oracle_schema              = "HR"                   # 請替換成您要遷移的 schema

# --- SageMaker User Segmentation Variables ---
# 請在下方填寫您自己的數值
sagemaker_artifacts_bucket_name = "my-awesome-project-sagemaker-artifacts-dev"

# 這是一個 K-Means 演算法在 us-east-1 區域的範例映像 URI。
# 您需要根據您的區域和選擇的演算法進行更改。
# 參考文檔: https://docs.aws.amazon.com/sagemaker/latest/dg/sagemaker-algo-docker-registry-paths.html
sagemaker_training_image_uri   = "811284229777.dkr.ecr.us-east-1.amazonaws.com/kmeans:1"

# --- Data Quality Check Variables ---
# 請在下方填寫您自己的數值
alert_email = "your-email@example.com" # AWS 會向此信箱發送一封確認郵件

# --- Salesforce Integration Variables ---
# 請在下方填寫您自己的數值
# 請注意：建議使用更安全的方式來管理密鑰，例如從 CI/CD 環境變數中讀取
salesforce_credentials_json = "{\"username\":\"your-sf-user@example.com\",\"password\":\"MustBeChanged3\",\"security_token\":\"YourSecurityToken\"}"