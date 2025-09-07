output "lambda_function_arn" {
  description = "The ARN of the Lambda function."
  value       = aws_lambda_function.csv_processor.arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function."
  value       = aws_lambda_function.csv_processor.function_name
}