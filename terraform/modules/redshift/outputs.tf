output "cluster_id" {
  description = "The ID of the Redshift cluster."
  value       = aws_redshift_cluster.default.id
}

output "cluster_endpoint" {
  description = "The endpoint of the Redshift cluster."
  value       = aws_redshift_cluster.default.endpoint
}

output "database_name" {
  description = "The name of the Redshift database."
  value       = aws_redshift_cluster.default.database_name
}