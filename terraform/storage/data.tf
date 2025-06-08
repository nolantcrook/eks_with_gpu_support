# Data sources
data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "main" {}


data "aws_secretsmanager_secret" "ses_email" {
  name = "ses/email-address"
}

data "aws_secretsmanager_secret" "ses_domain" {
  name = "ses/domain"
}

# Secret versions to get actual values
data "aws_secretsmanager_secret_version" "ses_email" {
  secret_id = data.aws_secretsmanager_secret.ses_email.id
}

data "aws_secretsmanager_secret_version" "ses_domain" {
  secret_id = data.aws_secretsmanager_secret.ses_domain.id
}
