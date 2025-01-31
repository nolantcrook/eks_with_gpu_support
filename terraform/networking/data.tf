# AWS Secrets Manager data sources
data "aws_secretsmanager_secret" "route53_zone_id" {
  arn = var.route53_zone_id_secret_arn
}

data "aws_secretsmanager_secret_version" "route53_zone_id" {
  secret_id = data.aws_secretsmanager_secret.route53_zone_id.id
}

# Parse the JSON from the secret
locals {
  route53_zone_id = jsondecode(data.aws_secretsmanager_secret_version.route53_zone_id.secret_string).zone_id
}
