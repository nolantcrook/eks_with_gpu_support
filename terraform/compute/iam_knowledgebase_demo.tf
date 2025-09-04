locals {
  knowledgebase_demo_service_account_namespace = "demo-knowledgebase"
  knowledgebase_demo_service_account_name      = "demo-knowledgebase-sa"
}

# IAM policy to allow access to required secrets and Bedrock services
resource "aws_iam_policy" "demo_knowledgebase_secrets_access" {
  name        = "demo-knowledgebase-secrets-access"
  description = "IAM policy to allow Knowledge Base Demo access to required secrets and Bedrock services"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          local.openai_api_key_secret_id,
          local.kaggle_username_secret_id,
          local.kaggle_key_secret_id,
          local.knowledge_base_id_secret_id
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:ListKnowledgeBases",
          "bedrock:GetKnowledgeBase",
          "bedrock:Retrieve",
          "bedrock:RetrieveAndGenerate"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock-agent:ListKnowledgeBases",
          "bedrock-agent:GetKnowledgeBase",
          "bedrock-agent-runtime:Retrieve",
          "bedrock-agent-runtime:RetrieveAndGenerate"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
          "lambda:List*",
          "lambda:Get*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:Get*",
          "dynamodb:Describe*",
          "dynamodb:List*"
        ]
        Resource = [
          "*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0",
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail",
          "ses:SendTemplatedEmail",
          "ses:SendBulkTemplatedEmail",
          "ses:GetSendQuota",
          "ses:GetSendStatistics",
          "ses:ListIdentities",
          "ses:GetIdentityVerificationAttributes",
          "ses:GetIdentityDkimAttributes",
          "ses:DescribeConfigurationSet",
          "ses:ListConfigurationSets"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*",
          "s3:Put*",
        ]
        Resource = [
          local.rag_s3_bucket_arn,
          "${local.rag_s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# IAM role for the Knowledge Base service account to assume
resource "aws_iam_role" "demo_knowledgebase_role" {
  name = "demo-knowledgebase-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${aws_iam_openid_connect_provider.eks_oidc.url}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "${aws_iam_openid_connect_provider.eks_oidc.url}:sub" = "system:serviceaccount:${local.knowledgebase_demo_service_account_namespace}:${local.knowledgebase_demo_service_account_name}"
          }
        }
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "demo_knowledgebase_secrets_access" {
  role       = aws_iam_role.demo_knowledgebase_role.name
  policy_arn = aws_iam_policy.demo_knowledgebase_secrets_access.arn
}

# Reference to remote state for foundation resources

# Output the role ARN for use in service account annotation
output "demo_knowledgebase_role_arn" {
  description = "ARN of IAM role for Knowledge Base Demo service account"
  value       = aws_iam_role.demo_knowledgebase_role.arn
}
