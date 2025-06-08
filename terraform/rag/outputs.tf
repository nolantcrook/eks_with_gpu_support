output "knowledge_base_id" {
  description = "ID of the Bedrock knowledge base"
  value       = aws_bedrockagent_knowledge_base.main.id
}

output "data_source_id" {
  description = "ID of the S3 data source"
  value       = aws_bedrockagent_data_source.s3_data_source.data_source_id
}

output "opensearch_collection_arn" {
  description = "ARN of the OpenSearch Serverless collection"
  value       = aws_opensearchserverless_collection.knowledge_base.arn
}

output "opensearch_collection_endpoint" {
  description = "Endpoint of the OpenSearch Serverless collection"
  value       = aws_opensearchserverless_collection.knowledge_base.collection_endpoint
}


output "auto_ingestion_status" {
  description = "Status of the automatic ingestion process"
  value       = var.auto_start_ingestion ? "Ingestion triggered automatically after apply - check logs above for status" : "Auto-ingestion disabled - run manual ingestion if needed"
  depends_on  = [null_resource.auto_start_ingestion]
}
