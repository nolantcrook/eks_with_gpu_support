data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "eks-stable-diffusion-terraform-state"
    key    = "${var.environment}/terraform/networking/terraform.tfstate"
    region = "us-west-2"
  }
}

data "terraform_remote_state" "storage" {
  backend = "s3"
  config = {
    bucket = "eks-stable-diffusion-terraform-state"
    key    = "${var.environment}/terraform/storage/terraform.tfstate"
    region = "us-west-2"
  }
}

data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket = "eks-stable-diffusion-terraform-state"
    key    = "${var.environment}/terraform/foundation/terraform.tfstate"
    region = "us-west-2"
  }
}

locals {
  private_subnet_ids        = data.terraform_remote_state.networking.outputs.private_subnet_ids
  public_subnet_ids         = data.terraform_remote_state.networking.outputs.public_subnet_ids
  cluster_security_group_id = data.terraform_remote_state.networking.outputs.cluster_security_group_id
  #ssh_private_key_secret_id = data.terraform_remote_state.foundation.outputs.ssh_private_key_secret_id
  # key_pair_id = data.terraform_remote_state.foundation.outputs.ec2_ssh_key_pair_id
  # Get ASG names from both node groups
  openai_api_key_secret_id       = data.terraform_remote_state.foundation.outputs.openai_api_key_secret_id
  kaggle_username_secret_id      = data.terraform_remote_state.foundation.outputs.kaggle_username_secret_id
  kaggle_key_secret_id           = data.terraform_remote_state.foundation.outputs.kaggle_key_secret_id
  ondemand_asg_name              = module.x86_ondemand_nodes.asg_name
  spot_asg_name                  = module.x86_spot_nodes.asg_name
  alb_target_group_arn           = data.terraform_remote_state.networking.outputs.alb_target_group_arn
  alb_target_group_websocket_arn = data.terraform_remote_state.networking.outputs.alb_target_group_websocket_arn
  knowledge_base_id_secret_id    = data.terraform_remote_state.foundation.outputs.knowledge_base_id_secret_id
  # hauliday_reservations_table_arn  = data.terraform_remote_state.storage.outputs.hauliday_reservations_table_arn
  hauliday_reservations_table_name = data.terraform_remote_state.storage.outputs.hauliday_reservations_table_name
  hauliday_reservations_stream_arn = data.terraform_remote_state.storage.outputs.hauliday_reservations_stream_arn
  knowledge_base_s3_bucket_arn     = data.terraform_remote_state.storage.outputs.knowledge_base_s3_bucket_arn
}

# Create attachments for both ASGs
resource "aws_autoscaling_attachment" "eks_ondemand_asg_attachment" {
  autoscaling_group_name = local.ondemand_asg_name
  lb_target_group_arn    = local.alb_target_group_arn
}

resource "aws_autoscaling_attachment" "eks_ondemand_asg_attachment_websocket" {
  autoscaling_group_name = local.ondemand_asg_name
  lb_target_group_arn    = local.alb_target_group_websocket_arn
}

resource "aws_autoscaling_attachment" "eks_spot_asg_attachment_spot" {
  autoscaling_group_name = local.spot_asg_name
  lb_target_group_arn    = local.alb_target_group_arn
}

resource "aws_autoscaling_attachment" "eks_spot_asg_attachment_websocket" {
  autoscaling_group_name = local.spot_asg_name
  lb_target_group_arn    = local.alb_target_group_websocket_arn
}

data "aws_caller_identity" "current" {}

# data "aws_secretsmanager_secret" "bastion_cidr_ranges" {
#   name = "bastion/allowed-cidr-ranges"
# }

# data "aws_secretsmanager_secret_version" "bastion_cidr_ranges" {
#   secret_id = data.aws_secretsmanager_secret.bastion_cidr_ranges.id
# }

# locals {
#   bastion_cidr_ranges = jsondecode(data.aws_secretsmanager_secret_version.bastion_cidr_ranges.secret_string)["cidr_ranges"]
# }
