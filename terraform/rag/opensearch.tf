# OpenSearch Serverless Collection (depends on security policies)
resource "aws_opensearchserverless_collection" "knowledge_base" {
  name = local.opensearch_collection_name
  type = "VECTORSEARCH"

  standby_replicas = "DISABLED"
  tags             = var.tags

}

################################################################################
# OpenSearch Serverless Security Policies
################################################################################

# OpenSearch Serverless Security Policies (must be created before collection)
resource "aws_opensearchserverless_security_policy" "knowledge_base_encryption" {
  name = "rag-knowledge-base-enc-policy"
  type = "encryption"

  policy = jsonencode({
    Rules = [
      {
        Resource = [
          "collection/${local.opensearch_collection_name}"
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
            "collection/${local.opensearch_collection_name}"
          ]
          ResourceType = "collection"
        }
      ]
      AllowFromPublic = true
    }
  ])
}



# OpenSearch Serverless Access Policy (depends on collection and IAM role)
resource "aws_opensearchserverless_access_policy" "knowledge_base" {
  name = "rag-knowledge-base-access-policy"
  type = "data"

  policy = jsonencode([
    {
      Rules = [
        {
          Resource = [
            "collection/${local.opensearch_collection_name}"
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
            "index/${local.opensearch_collection_name}/*"
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
        aws_iam_role.bedrock_knowledge_base_role.arn,
        data.aws_caller_identity.current.arn
      ]
    }
  ])

}

################################################################################
# Create OpenSearch Index with proper mapping for Bedrock Knowledge Base
################################################################################

resource "null_resource" "create_opensearch_index" {
  provisioner "local-exec" {
    command     = <<-EOT
      # Install required Python packages
      pip3 install opensearch-py aws-requests-auth boto3

      # Wait for collection to be ready
      sleep 30

      # Create index using Python script
      python3 create_index.py "${aws_opensearchserverless_collection.knowledge_base.collection_endpoint}" "bedrock-knowledge-base-v3-index"
    EOT
    working_dir = path.module
  }

  depends_on = [
    aws_opensearchserverless_collection.knowledge_base,
    aws_opensearchserverless_access_policy.knowledge_base
  ]

  triggers = {
    collection_endpoint = aws_opensearchserverless_collection.knowledge_base.collection_endpoint
  }
}
