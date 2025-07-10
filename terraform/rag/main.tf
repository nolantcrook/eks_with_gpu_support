# Bedrock Knowledge Base
resource "aws_bedrockagent_knowledge_base" "main" {
  name     = var.knowledge_base_name
  role_arn = aws_iam_role.bedrock_knowledge_base_role.arn

  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:${var.aws_region}::foundation-model/amazon.titan-embed-text-v2:0"
    }
    type = "VECTOR"
  }

  storage_configuration {
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.knowledge_base.arn
      vector_index_name = "bedrock-knowledge-base-v3-index"
      field_mapping {
        vector_field   = "bedrock-knowledge-base-v3-vector"
        text_field     = "AMAZON_BEDROCK_TEXT"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
    type = "OPENSEARCH_SERVERLESS"
  }

  tags = var.tags

  depends_on = [
    null_resource.create_opensearch_index
  ]
}

# Data Source for the Knowledge Base (S3)
resource "aws_bedrockagent_data_source" "s3_data_source" {
  knowledge_base_id    = aws_bedrockagent_knowledge_base.main.id
  name                 = "s3-data-source"
  data_deletion_policy = "RETAIN"
  data_source_configuration {
    s3_configuration {
      bucket_arn         = local.rag_s3_bucket_arn
      inclusion_prefixes = ["knowledgebase-demo"]
    }
    type = "S3"
  }

}

################################################################################
# Auto-start ingestion after knowledge base and data source are created
################################################################################

resource "null_resource" "auto_start_ingestion" {
  count = var.auto_start_ingestion ? 1 : 0

  provisioner "local-exec" {
    command     = <<-EOT
      echo "🚀 Starting automatic ingestion for Knowledge Base..."
      echo "Knowledge Base ID: ${aws_bedrockagent_knowledge_base.main.id}"
      echo "Data Source ID: ${aws_bedrockagent_data_source.s3_data_source.data_source_id}"
      echo "Timeout: ${var.ingestion_timeout_minutes} minutes"
      echo "Region: ${var.aws_region}"
      echo ""
      python3 auto_ingestion.py "${aws_bedrockagent_knowledge_base.main.id}" "${aws_bedrockagent_data_source.s3_data_source.data_source_id}" --region "${var.aws_region}" --timeout ${var.ingestion_timeout_minutes}
    EOT
    working_dir = path.module
  }

  depends_on = [
    aws_bedrockagent_knowledge_base.main,
    aws_bedrockagent_data_source.s3_data_source
  ]

  triggers = {
    knowledge_base_id = aws_bedrockagent_knowledge_base.main.id
    data_source_id    = aws_bedrockagent_data_source.s3_data_source.data_source_id
    auto_ingestion    = var.auto_start_ingestion
    timeout_minutes   = var.ingestion_timeout_minutes
    # Trigger re-ingestion if the S3 bucket content changes (optional)
    # s3_bucket_arn     = aws_s3_bucket.knowledge_base_data.arn
  }
}
