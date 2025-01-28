# Create AWS Secrets Manager secret for GitHub credentials
resource "aws_secretsmanager_secret" "github_credentials" {
  name        = "github/stable-diff-gitops-secret"
  description = "GitHub credentials for ArgoCD"
}

# Create initial secret version with placeholder values
# You'll need to update these values manually through AWS Console or CLI
resource "aws_secretsmanager_secret_version" "github_credentials" {
  secret_id = aws_secretsmanager_secret.github_credentials.id
  secret_string = jsonencode({
    username = "placeholder-username"
    token    = "placeholder-token"
  })
}

# IAM policy to allow EKS cluster to read the secret
resource "aws_iam_policy" "secrets_access" {
  name        = "eks-github-secrets"
  description = "Allow EKS to access GitHub credentials in Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [aws_secretsmanager_secret.github_credentials.arn]
      }
    ]
  })
}

# Create AWS Secrets Manager secret for Route53 Zone ID
resource "aws_secretsmanager_secret" "route53_zone_id" {
  name        = "route53/zone-id-hello-world-domain"
  description = "Route53 Zone ID for DNS management"
}

resource "aws_secretsmanager_secret_version" "route53_zone_id" {
  secret_id = aws_secretsmanager_secret.route53_zone_id.id
  secret_string = jsonencode({
    zone_id = "add zone here"
  })
}
