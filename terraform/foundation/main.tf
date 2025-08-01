# Create AWS Secrets Manager secret for GitHub credentials
resource "aws_secretsmanager_secret" "github_credentials" {
  name        = "github/argocd-gitops-secret"
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
  name        = "route53/zone-id-website-domain"
  description = "Route53 Zone ID for DNS management"
}

resource "aws_secretsmanager_secret_version" "route53_zone_id" {
  secret_id = aws_secretsmanager_secret.route53_zone_id.id
  secret_string = jsonencode({
    zone_id = "add zone here"
  })
}

# Create AWS Secrets Manager secret for Route53 Zone ID
resource "aws_secretsmanager_secret" "route53_zone_id_pic" {
  name        = "route53/zone-id-pic-domain"
  description = "Route53 Zone ID for DNS management"
}

resource "aws_secretsmanager_secret_version" "route53_zone_id_pic" {
  secret_id = aws_secretsmanager_secret.route53_zone_id_pic.id
  secret_string = jsonencode({
    zone_id = "add zone here"
  })
}

# Create AWS Secrets Manager secret for Route53 Zone ID
resource "aws_secretsmanager_secret" "route53_zone_id_stratis" {
  name        = "route53/zone-id-stratis-domain"
  description = "Route53 Zone ID for DNS management"
}

resource "aws_secretsmanager_secret_version" "route53_zone_id_hauliday" {
  secret_id = aws_secretsmanager_secret.route53_zone_id_hauliday.id
  secret_string = jsonencode({
    zone_id = "add zone here"
  })
}

# Create AWS Secrets Manager secret for Route53 Zone ID
resource "aws_secretsmanager_secret" "route53_zone_id_hauliday" {
  name        = "route53/zone-id-hauliday-domain"
  description = "Route53 Zone ID for DNS management"
}

resource "aws_secretsmanager_secret_version" "route53_zone_id_stratis" {
  secret_id = aws_secretsmanager_secret.route53_zone_id_stratis.id
  secret_string = jsonencode({
    zone_id = "add zone here"
  })
}


# Create AWS Secrets Manager secret for Route53 Zone ID
resource "aws_secretsmanager_secret" "route53_zone_id_tolby" {
  name        = "route53/zone-id-tolby-domain"
  description = "Route53 Zone ID for DNS management"
}

resource "aws_secretsmanager_secret_version" "route53_zone_id_tolby" {
  secret_id = aws_secretsmanager_secret.route53_zone_id_tolby.id
  secret_string = jsonencode({
    zone_id = "add zone here"
  })
}

# Create AWS Secrets Manager secret for Route53 Zone ID
resource "aws_secretsmanager_secret" "route53_zone_id_treasure" {
  name        = "route53/zone-id-treasure-domain"
  description = "Route53 Zone ID for DNS management"
}

resource "aws_secretsmanager_secret_version" "route53_zone_id_treasure" {
  secret_id = aws_secretsmanager_secret.route53_zone_id_treasure.id
  secret_string = jsonencode({
    zone_id = "add zone here"
  })
}



resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "key_pair"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Create AWS Secrets Manager secret for SSH private key
resource "aws_secretsmanager_secret" "ssh_private_key" {
  name        = "ssh/key-pair-private-key"
  description = "SSH private key for EC2 instances"
}

# Create initial secret version with the private key
resource "aws_secretsmanager_secret_version" "ssh_private_key" {
  secret_id     = aws_secretsmanager_secret.ssh_private_key.id
  secret_string = tls_private_key.ssh_key.private_key_pem
}

resource "aws_secretsmanager_secret" "HF_TOKEN" {
  name        = "huggingface/token"
  description = "Huggingface token"
}

# Create initial secret version with placeholder values
# You'll need to update these values manually through AWS Console or CLI
resource "aws_secretsmanager_secret_version" "HF_TOKEN" {
  secret_id = aws_secretsmanager_secret.HF_TOKEN.id
  secret_string = jsonencode({
    token = "placeholder-token"
  })
}
# Create AWS Secrets Manager secret for bastion host CIDR ranges
resource "aws_secretsmanager_secret" "bastion_cidr_ranges" {
  name        = "bastion/allowed-cidr-ranges"
  description = "CIDR ranges allowed to access the bastion host"
}

# Create initial secret version with placeholder CIDR ranges
resource "aws_secretsmanager_secret_version" "bastion_cidr_ranges" {
  secret_id = aws_secretsmanager_secret.bastion_cidr_ranges.id
  secret_string = jsonencode({
    cidr_ranges = [
      "0.0.0.0/0" # Additional IP if needed
    ]
  })
}

# Create AWS Secrets Manager secret for OpenAI API key
resource "aws_secretsmanager_secret" "openai_api_key" {
  name        = "langchain/openai-api-key"
  description = "OpenAI API key for LangChain applications"
}

# Create initial secret version with placeholder value
resource "aws_secretsmanager_secret_version" "openai_api_key" {
  secret_id = aws_secretsmanager_secret.openai_api_key.id
  secret_string = jsonencode({
    key = "placeholder-openai-api-key"
  })
}

# Create AWS Secrets Manager secret for OpenAI API key
resource "aws_secretsmanager_secret" "umami_postgres_user" {
  name        = "umami/postgres-user"
  description = "Umami postgres user"
}

# Create initial secret version with placeholder value
resource "aws_secretsmanager_secret_version" "umami_postgres_user" {
  secret_id = aws_secretsmanager_secret.umami_postgres_user.id
  secret_string = jsonencode({
    user = "placeholder-umami-postgres-user"
  })
}

# Create AWS Secrets Manager secret for OpenAI API key
resource "aws_secretsmanager_secret" "umami_password" {
  name        = "umami/password"
  description = "Umami password"
}

# Create initial secret version with placeholder value
resource "aws_secretsmanager_secret_version" "umami_password" {
  secret_id = aws_secretsmanager_secret.umami_password.id
  secret_string = jsonencode({
    password = "placeholder-umami-password"
  })
}

# Create AWS Secrets Manager secret for OpenAI API key
resource "aws_secretsmanager_secret" "umami_postgres_password" {
  name        = "umami/postgres-password"
  description = "Umami postgres password"
}

# Create initial secret version with placeholder value
resource "aws_secretsmanager_secret_version" "umami_postgres_password" {
  secret_id = aws_secretsmanager_secret.umami_postgres_password.id
  secret_string = jsonencode({
    password = "placeholder-umami-postgres-password"
  })
}

# Create AWS Secrets Manager secret for OpenAI API key
resource "aws_secretsmanager_secret" "umami_app_secret" {
  name        = "umami/app-secret"
  description = "Umami app secret"
}

# Create initial secret version with placeholder value
resource "aws_secretsmanager_secret_version" "umami_app_secret" {
  secret_id = aws_secretsmanager_secret.umami_app_secret.id
  secret_string = jsonencode({
    secret = "placeholder-umami-app-secret"
  })
}


# Create AWS Secrets Manager secret for Kaggle username
resource "aws_secretsmanager_secret" "kaggle_username" {
  name        = "langchain/kaggle-username"
  description = "Kaggle username for dataset access"
}

# Create initial secret version with placeholder value
resource "aws_secretsmanager_secret_version" "kaggle_username" {
  secret_id = aws_secretsmanager_secret.kaggle_username.id
  secret_string = jsonencode({
    username = "placeholder-kaggle-username"
  })
}

# Create AWS Secrets Manager secret for Kaggle key
resource "aws_secretsmanager_secret" "kaggle_key" {
  name        = "langchain/kaggle-key"
  description = "Kaggle API key for dataset access"
}

# Create initial secret version with placeholder value
resource "aws_secretsmanager_secret_version" "kaggle_key" {
  secret_id = aws_secretsmanager_secret.kaggle_key.id
  secret_string = jsonencode({
    key = "placeholder-kaggle-key"
  })
}

# Create AWS Secrets Manager secret for SES email address
resource "aws_secretsmanager_secret" "ses_email" {
  name        = "ses/email-address"
  description = "SES verified email address for sending emails"
}

# Create initial secret version with placeholder value
resource "aws_secretsmanager_secret_version" "ses_email" {
  secret_id = aws_secretsmanager_secret.ses_email.id
  secret_string = jsonencode({
    email = "placeholder@example.com"
  })
}

# Create AWS Secrets Manager secret for SES domain
resource "aws_secretsmanager_secret" "ses_domain" {
  name        = "ses/domain"
  description = "SES verified domain for sending emails"
}

# Create initial secret version with placeholder value
resource "aws_secretsmanager_secret_version" "ses_domain" {
  secret_id = aws_secretsmanager_secret.ses_domain.id
  secret_string = jsonencode({
    domain = "example.com"
  })
}

# Create a secret for the knowledge base ID
resource "aws_secretsmanager_secret" "knowledge_base_id" {
  name        = "rag-project-knowledge-base-id"
  description = "Secret containing the knowledge base ID for RAG application"
}
