output "github_secret_arn" {
  description = "ARN of the GitHub credentials secret"
  value       = aws_secretsmanager_secret.github_credentials.arn
}

output "secrets_access_policy_arn" {
  description = "ARN of the IAM policy for secrets access"
  value       = aws_iam_policy.secrets_access.arn
}

output "route53_zone_id_secret_arn" {
  description = "ARN of the Route53 Zone ID secret"
  value       = aws_secretsmanager_secret.route53_zone_id.arn
}

output "route53_zone_id_secret_arn_pic" {
  description = "ARN of the Route53 Zone ID secret"
  value       = aws_secretsmanager_secret.route53_zone_id_pic.arn
}

output "route53_zone_id_secret_arn_stratis" {
  description = "ARN of the Route53 Zone ID secret"
  value       = aws_secretsmanager_secret.route53_zone_id_stratis.arn
}

output "route53_zone_id_secret_arn_hauliday" {
  description = "ARN of the Route53 Zone ID secret"
  value       = aws_secretsmanager_secret.route53_zone_id_hauliday.arn
}

output "route53_zone_id_secret_arn_tolby" {
  description = "ARN of the Route53 Zone ID secret"
  value       = aws_secretsmanager_secret.route53_zone_id_tolby.arn
}

output "ec2_ssh_key_pair_id" {
  description = "The ID of the EC2 SSH key pair"
  value       = aws_key_pair.ec2_key_pair.id
}

output "ssh_private_key_secret_id" {
  description = "ID of the SSH private key secret"
  value       = aws_secretsmanager_secret.ssh_private_key.id
}

output "openai_api_key_secret_id" {
  description = "ID of the OpenAI API key secret"
  value       = aws_secretsmanager_secret.openai_api_key.id
}

output "kaggle_username_secret_id" {
  description = "ID of the Kaggle username secret"
  value       = aws_secretsmanager_secret.kaggle_username.id
}

output "kaggle_key_secret_id" {
  description = "ID of the Kaggle key secret"
  value       = aws_secretsmanager_secret.kaggle_key.id
}

output "ses_email_secret_id" {
  description = "ID of the SES email secret"
  value       = aws_secretsmanager_secret.ses_email.id
}

output "ses_domain_secret_id" {
  description = "ID of the SES domain secret"
  value       = aws_secretsmanager_secret.ses_domain.id
}

output "knowledge_base_id_secret_id" {
  description = "ID of the knowledge base ID secret"
  value       = aws_secretsmanager_secret.knowledge_base_id.id
}
