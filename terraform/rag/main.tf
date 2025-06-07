

# Bedrock Knowledge Base
resource "aws_bedrockagent_knowledge_base" "main" {
  name     = var.knowledge_base_name
  role_arn = aws_iam_role.bedrock_knowledge_base_role.arn

  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:${var.aws_region}::foundation-model/amazon.titan-embed-text-v2:0"
      embedding_model_configuration {
        bedrock_embedding_model_configuration {
          dimensions = 1024
        }
      }
    }
    type = "VECTOR"
  }

  storage_configuration {
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.knowledge_base.arn
      vector_index_name = "bedrock-knowledge-base-default-index"
      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
    type = "OPENSEARCH_SERVERLESS"
  }

  tags = var.tags

}

# Data Source for the Knowledge Base (S3)
resource "aws_bedrockagent_data_source" "s3_data_source" {
  knowledge_base_id    = aws_bedrockagent_knowledge_base.main.id
  name                 = "s3-data-source"
  data_deletion_policy = "RETAIN"
  data_source_configuration {
    s3_configuration {
      bucket_arn         = aws_s3_bucket.knowledge_base_data.arn
      inclusion_prefixes = ["knowledgebase-demo"]
    }
    type = "S3"
  }

}
