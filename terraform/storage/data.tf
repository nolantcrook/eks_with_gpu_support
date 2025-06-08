# Data sources
data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "main" {}


data "aws_secretsmanager_secret" "ses_email" {
  name = "ses/email-address"
}

data "aws_secretsmanager_secret" "ses_domain" {
  name = "ses/domain"
}
