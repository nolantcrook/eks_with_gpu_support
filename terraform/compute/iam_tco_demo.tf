locals {
  tco_demo_service_account_namespace = "tco-demo"
  tco_demo_service_account_name      = "tco-demo-sa"
}

# IAM policy to allow access to required secrets
resource "aws_iam_policy" "tco_demo_secrets_access" {
  name        = "tco-demo-secrets-access"
  description = "IAM policy to allow TCO Demo access to required secrets in Secrets Manager"

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
resource "aws_iam_role" "tco_demo_role" {
  name = "tco-demo-role"

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
            "${aws_iam_openid_connect_provider.eks_oidc.url}:sub" = "system:serviceaccount:${local.tco_demo_service_account_namespace}:${local.tco_demo_service_account_name}"
          }
        }
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "tco_demo_secrets_access" {
  role       = aws_iam_role.tco_demo_role.name
  policy_arn = aws_iam_policy.tco_demo_secrets_access.arn
}

# Reference to remote state for foundation resources

# Output the role ARN for use in service account annotation
output "tco_demo_role_arn" {
  description = "ARN of IAM role for TCO Demo service account"
  value       = aws_iam_role.tco_demo_role.arn
}
