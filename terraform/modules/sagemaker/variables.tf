
variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "notebook_instance_type" {
  description = "The instance type for the SageMaker notebook."
  type        = string
  default     = "ml.t2.medium"
}

variable "inference_instance_type" {
  description = "The instance type for the SageMaker inference endpoint."
  type        = string
  default     = "ml.t2.medium"
}

variable "training_image_uri" {
  description = "The ECR URI of the Docker image to use for training."
  type        = string
}

variable "s3_model_artifacts_bucket" {
  description = "The S3 bucket where the trained model artifacts are stored."
  type        = string
}

variable "model_artifacts_path" {
  description = "The path within the S3 bucket to the model artifacts."
  type        = string
}
