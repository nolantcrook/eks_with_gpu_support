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
  efs_file_system_id              = data.terraform_remote_state.storage.outputs.efs_file_system_id
  website_dns_zone_id_secret_arn  = data.terraform_remote_state.foundation.outputs.route53_zone_id_secret_arn
  pic_dns_zone_id_secret_arn      = data.terraform_remote_state.foundation.outputs.route53_zone_id_secret_arn_pic
  stratis_dns_zone_id_secret_arn  = data.terraform_remote_state.foundation.outputs.route53_zone_id_secret_arn_stratis
  hauliday_dns_zone_id_secret_arn = data.terraform_remote_state.foundation.outputs.route53_zone_id_secret_arn_hauliday
  tolby_dns_zone_id_secret_arn    = data.terraform_remote_state.foundation.outputs.route53_zone_id_secret_arn_tolby
  treasure_dns_zone_id_secret_arn = data.terraform_remote_state.foundation.outputs.route53_zone_id_secret_arn_treasure
  ec2_ssh_key_pair_id             = data.terraform_remote_state.foundation.outputs.ec2_ssh_key_pair_id
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

data "aws_secretsmanager_secret" "route53_zone_id_stratis_arn" {
  arn = local.stratis_dns_zone_id_secret_arn
}

data "aws_secretsmanager_secret_version" "route53_zone_id_stratis" {
  secret_id = data.aws_secretsmanager_secret.route53_zone_id_stratis_arn.id
}

data "aws_route53_zone" "hosted_zone_stratis" {
  zone_id = local.route53_zone_id_stratis
}


data "aws_secretsmanager_secret" "route53_zone_id_hauliday_arn" {
  arn = local.hauliday_dns_zone_id_secret_arn
}

data "aws_secretsmanager_secret_version" "route53_zone_id_hauliday" {
  secret_id = data.aws_secretsmanager_secret.route53_zone_id_hauliday_arn.id
}

data "aws_route53_zone" "hosted_zone_hauliday" {
  zone_id = local.route53_zone_id_hauliday
}

data "aws_secretsmanager_secret" "route53_zone_id_tolby_arn" {
  arn = local.tolby_dns_zone_id_secret_arn
}

data "aws_secretsmanager_secret_version" "route53_zone_id_tolby" {
  secret_id = data.aws_secretsmanager_secret.route53_zone_id_tolby_arn.id
}

data "aws_route53_zone" "hosted_zone_tolby" {
  zone_id = local.route53_zone_id_tolby
}

data "aws_secretsmanager_secret" "route53_zone_id_treasure_arn" {
  arn = local.treasure_dns_zone_id_secret_arn
}

data "aws_secretsmanager_secret_version" "route53_zone_id_treasure" {
  secret_id = data.aws_secretsmanager_secret.route53_zone_id_treasure_arn.id
}

data "aws_route53_zone" "hosted_zone_treasure" {
  zone_id = local.route53_zone_id_treasure
}



locals {
  route53_zone_id            = jsondecode(data.aws_secretsmanager_secret_version.route53_zone_id.secret_string).zone_id
  route53_zone_name          = data.aws_route53_zone.hosted_zone.name
  route53_zone_id_pic        = jsondecode(data.aws_secretsmanager_secret_version.route53_zone_id_pic.secret_string).zone_id
  route53_zone_name_pic      = data.aws_route53_zone.hosted_zone_pic.name
  route53_zone_id_stratis    = jsondecode(data.aws_secretsmanager_secret_version.route53_zone_id_stratis.secret_string).zone_id
  route53_zone_name_stratis  = data.aws_route53_zone.hosted_zone_stratis.name
  route53_zone_id_hauliday   = jsondecode(data.aws_secretsmanager_secret_version.route53_zone_id_hauliday.secret_string).zone_id
  route53_zone_name_hauliday = data.aws_route53_zone.hosted_zone_hauliday.name
  route53_zone_id_tolby      = jsondecode(data.aws_secretsmanager_secret_version.route53_zone_id_tolby.secret_string).zone_id
  route53_zone_name_tolby    = data.aws_route53_zone.hosted_zone_tolby.name
  route53_zone_id_treasure   = jsondecode(data.aws_secretsmanager_secret_version.route53_zone_id_treasure.secret_string).zone_id
  route53_zone_name_treasure = data.aws_route53_zone.hosted_zone_treasure.name
  alb_logs_bucket_arn        = data.terraform_remote_state.storage.outputs.alb_logs_bucket_arn
}
