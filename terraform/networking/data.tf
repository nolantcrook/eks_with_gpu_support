# Parse the JSON from the secret


data "terraform_remote_state" "storage" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/terraform/storage/terraform.tfstate"
    region = "us-west-2"
  }
}

data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/terraform/foundation/terraform.tfstate"
    region = "us-west-2"
  }
}

locals {
  efs_file_system_id             = data.terraform_remote_state.storage.outputs.efs_file_system_id
  website_dns_zone_id_secret_arn = data.terraform_remote_state.foundation.outputs.route53_zone_id_secret_arn
  pic_dns_zone_id_secret_arn     = data.terraform_remote_state.foundation.outputs.route53_zone_id_secret_arn_pic
}

data "aws_secretsmanager_secret" "route53_zone_id_arn" {
  arn = local.website_dns_zone_id_secret_arn
}

data "aws_secretsmanager_secret_version" "route53_zone_id" {
  secret_id = data.aws_secretsmanager_secret.route53_zone_id_arn.id
}

data "aws_route53_zone" "hosted_zone" {
  zone_id = local.route53_zone_id
}

data "aws_secretsmanager_secret" "route53_zone_id_pic_arn" {
  arn = local.pic_dns_zone_id_secret_arn
}

data "aws_secretsmanager_secret_version" "route53_zone_id_pic" {
  secret_id = data.aws_secretsmanager_secret.route53_zone_id_pic_arn.id
}

data "aws_route53_zone" "hosted_zone_pic" {
  zone_id = local.route53_zone_id_pic
}

locals {
  route53_zone_id       = jsondecode(data.aws_secretsmanager_secret_version.route53_zone_id.secret_string).zone_id
  route53_zone_name     = data.aws_route53_zone.hosted_zone.name
  route53_zone_id_pic   = jsondecode(data.aws_secretsmanager_secret_version.route53_zone_id_pic.secret_string).zone_id
  route53_zone_name_pic = data.aws_route53_zone.hosted_zone_pic.name
  alb_logs_bucket_arn   = data.terraform_remote_state.storage.outputs.alb_logs_bucket_arn
}
