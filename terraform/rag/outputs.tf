output "knowledge_base_id" {
  description = "ID of the Bedrock Knowledge Base"
  value       = aws_bedrockagent_knowledge_base.main.id
}

output "knowledge_base_arn" {
  description = "ARN of the Bedrock Knowledge Base"
  value       = aws_bedrockagent_knowledge_base.main.arn
}

output "opensearch_serverless_collection_arn" {
  description = "ARN of the OpenSearch Serverless collection"
  value       = aws_opensearchserverless_collection.knowledge_base.arn
}

output "opensearch_serverless_collection_endpoint" {
  description = "Endpoint of the OpenSearch Serverless collection"
  value       = aws_opensearchserverless_collection.knowledge_base.collection_endpoint
}

output "s3_data_bucket_name" {
  description = "Name of the S3 bucket for knowledge base data"
  value       = aws_s3_bucket.knowledge_base_data.bucket
}

output "s3_data_bucket_arn" {
  description = "ARN of the S3 bucket for knowledge base data"
  value       = aws_s3_bucket.knowledge_base_data.arn
}

# output "bedrock_role_arn" {
#   description = "ARN of the Bedrock execution role"
#   value       = aws_iam_role.bedrock_execution_role.arn
# }

# output "bedrock_knowledge_base_role_arn" {
#   description = "ARN of the Bedrock Knowledge Base role"
#   value       = aws_iam_role.bedrock_knowledge_base_role.arn
# }

output "data_source_id" {
  description = "ID of the Knowledge Base data source"
  value       = aws_bedrockagent_data_source.s3_data_source.data_source_id
}
