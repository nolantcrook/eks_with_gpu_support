locals {
  langchain_service_account_namespace = "langchain"
  langchain_service_account_name      = "langchain-sa"
}

# IAM policy to allow access to required secrets
resource "aws_iam_policy" "langchain_secrets_access" {
  name        = "langchain-secrets-access"
  description = "IAM policy to allow LangChain access to required secrets in Secrets Manager"

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
          local.kaggle_key_secret_id
        ]
      }
    ]
  })
}

# IAM role for the LangChain service account to assume
resource "aws_iam_role" "langchain_role" {
  name = "langchain-role"

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
            "${aws_iam_openid_connect_provider.eks_oidc.url}:sub" = "system:serviceaccount:${local.langchain_service_account_namespace}:${local.langchain_service_account_name}"
          }
        }
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "langchain_secrets_access" {
  role       = aws_iam_role.langchain_role.name
  policy_arn = aws_iam_policy.langchain_secrets_access.arn
}

# Reference to remote state for foundation resources

# Output the role ARN for use in service account annotation
output "langchain_role_arn" {
  description = "ARN of IAM role for LangChain service account"
  value       = aws_iam_role.langchain_role.arn
}
