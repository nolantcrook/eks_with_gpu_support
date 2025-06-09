# Data source to reference the secret created in foundation
data "aws_secretsmanager_secret" "knowledge_base_id" {
  name = "rag-project-knowledge-base-id"
}

# Update the secret with the actual knowledge base ID
resource "aws_secretsmanager_secret_version" "knowledge_base_id" {
  secret_id     = data.aws_secretsmanager_secret.knowledge_base_id.id
  secret_string = aws_bedrockagent_knowledge_base.main.id
}

output "knowledge_base_secret_arn" {
  description = "ARN of the secret containing the knowledge base ID"
  value       = data.aws_secretsmanager_secret.knowledge_base_id.arn
}
