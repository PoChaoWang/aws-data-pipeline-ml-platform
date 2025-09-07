output "glue_job_name" {
  description = "The name of the Glue job."
  value       = aws_glue_job.csv_to_redshift.name
}

output "glue_job_arn" {
  description = "The ARN of the Glue job."
  value       = aws_glue_job.csv_to_redshift.arn
}