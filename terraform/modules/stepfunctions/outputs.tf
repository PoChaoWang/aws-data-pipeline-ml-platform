output "step_function_arn" {
  description = "The ARN of the created Step Function state machine."
  value       = aws_sfn_state_machine.ml_pipeline.arn
}

output "step_function_name" {
  description = "The name of the created Step Function state machine."
  value       = aws_sfn_state_machine.ml_pipeline.name
}