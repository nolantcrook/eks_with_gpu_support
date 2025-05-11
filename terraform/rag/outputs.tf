
output "neptune_endpoint" {
  description = "Neptune cluster endpoint"
  value       = aws_neptune_cluster.main.endpoint
}

output "neptune_reader_endpoint" {
  description = "Neptune cluster reader endpoint"
  value       = aws_neptune_cluster.main.reader_endpoint
}

output "opensearch_endpoint" {
  description = "OpenSearch domain endpoint"
  value       = aws_opensearch_domain.main.endpoint
}

output "opensearch_dashboard_endpoint" {
  description = "OpenSearch dashboard endpoint"
  value       = aws_opensearch_domain.main.dashboard_endpoint
}

output "bedrock_role_arn" {
  description = "ARN of the Bedrock execution role"
  value       = aws_iam_role.bedrock_execution_role.arn
}
