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

output "ec2_ssh_key_pair_id" {
  description = "The ID of the EC2 SSH key pair"
  value       = aws_key_pair.ec2_key_pair.id
}

output "ssh_private_key_secret_id" {
  description = "ID of the SSH private key secret"
  value       = aws_secretsmanager_secret.ssh_private_key.id
}
