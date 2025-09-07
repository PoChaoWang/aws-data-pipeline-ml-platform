resource "aws_sfn_state_machine" "ml_pipeline" {
  name     = "${var.name_prefix}MLPipelineStateMachine"
  role_arn = var.sfn_execution_role_arn # This role needs permissions to invoke Glue and SageMaker
  definition = file("${path.module}/../../step-functions/ml-pipeline.json")

  tags = var.tags
}

variable "sfn_execution_role_arn" {
  description = "The ARN of the IAM role that the Step Function will assume."
  type        = string
}