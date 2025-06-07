# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "opensearch_collection_logs" {
  name              = "/aws/opensearchserverless/collections/${aws_opensearchserverless_collection.knowledge_base.name}"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "bedrock_knowledge_base_logs" {
  name              = "/aws/bedrock/knowledgebases/${aws_bedrockagent_knowledge_base.main.name}"
  retention_in_days = 14
  tags              = var.tags
}
