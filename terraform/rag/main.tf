

# S3 Bucket for Knowledge Base Data Sources
resource "aws_s3_bucket" "knowledge_base_data" {
  bucket = "rag-knowledge-base-data-${data.aws_caller_identity.current.account_id}"
  tags   = var.tags


}

resource "aws_s3_bucket_versioning" "knowledge_base_data" {
  bucket = aws_s3_bucket.knowledge_base_data.id
  versioning_configuration {
    status = "Enabled"
  }
}


# OpenSearch Serverless Collection
resource "aws_opensearchserverless_collection" "knowledge_base" {
  name = "rag-knowledge-base-collection"
  type = "VECTORSEARCH"

  tags = var.tags
}

# OpenSearch Serverless Security Policy
resource "aws_opensearchserverless_security_policy" "knowledge_base_encryption" {
  name = "rag-knowledge-base-enc-policy"
  type = "encryption"

  policy = jsonencode({
    Rules = [
      {
        Resource = [
          "collection/rag-knowledge-base-collection"
        ]
        ResourceType = "collection"
      }
    ]
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "knowledge_base_network" {
  name = "rag-knowledge-base-net-policy"
  type = "network"

  policy = jsonencode([
    {
      Rules = [
        {
          Resource = [
            "collection/rag-knowledge-base-collection"
          ]
          ResourceType = "collection"
        }
      ]
      AllowFromPublic = true
    }
  ])
}

# OpenSearch Serverless Access Policy
resource "aws_opensearchserverless_access_policy" "knowledge_base" {
  name = "rag-knowledge-base-access-policy"
  type = "data"

  policy = jsonencode([
    {
      Rules = [
        {
          Resource = [
            "collection/rag-knowledge-base-collection"
          ]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:DeleteCollectionItems",
            "aoss:UpdateCollectionItems",
            "aoss:DescribeCollectionItems"
          ]
          ResourceType = "collection"
        },
        {
          Resource = [
            "index/rag-knowledge-base-collection/*"
          ]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DeleteIndex",
            "aoss:UpdateIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument"
          ]
          ResourceType = "index"
        }
      ]
      Principal = [
        aws_iam_role.bedrock_knowledge_base_role.arn
      ]
    }
  ])
}

# Bedrock Knowledge Base
resource "aws_bedrockagent_knowledge_base" "main" {
  name     = "rag-knowledge-base"
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

  depends_on = [
    aws_opensearchserverless_collection.knowledge_base,
    aws_opensearchserverless_access_policy.knowledge_base
  ]
}

# Data Source for the Knowledge Base (S3)
resource "aws_bedrockagent_data_source" "s3_data_source" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.main.id
  name              = "s3-data-source"

  data_source_configuration {
    s3_configuration {
      bucket_arn         = aws_s3_bucket.knowledge_base_data.arn
      inclusion_prefixes = ["knowledgebase-demo"]
    }
    type = "S3"
  }
}
