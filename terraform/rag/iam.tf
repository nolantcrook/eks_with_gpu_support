# IAM Role for Bedrock Knowledge Base
resource "aws_iam_role" "bedrock_knowledge_base_role" {
  name = "rag-bedrock-knowledge-base-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Bedrock Knowledge Base
resource "aws_iam_role_policy" "bedrock_knowledge_base_policy" {
  name = "rag-bedrock-knowledge-base-policy"
  role = aws_iam_role.bedrock_knowledge_base_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = [
          "arn:aws:bedrock:${var.aws_region}::foundation-model/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "aoss:APIAccessAll"
        ]
        Resource = [
          aws_opensearchserverless_collection.knowledge_base.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.knowledge_base_data.arn,
          "${aws_s3_bucket.knowledge_base_data.arn}/*",
          "arn:aws:s3:::rag-uploads-${data.aws_caller_identity.current.account_id}",
          "arn:aws:s3:::rag-uploads-${data.aws_caller_identity.current.account_id}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = [data.aws_caller_identity.current.account_id]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock/knowledgebases/*",
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/opensearchserverless/collections/*"
        ]
      }
    ]
  })
}
