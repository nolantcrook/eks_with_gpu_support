output "github_secret_arn" {
  description = "ARN of the GitHub credentials secret"
  value       = aws_secretsmanager_secret.github_credentials.arn
}

output "secrets_access_policy_arn" {
  description = "ARN of the IAM policy for secrets access"
  value       = aws_iam_policy.secrets_access.arn
}