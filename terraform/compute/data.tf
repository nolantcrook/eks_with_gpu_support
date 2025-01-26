data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "eks-stable-diffusion-terraform-state"
    key    = "${var.environment}/terraform/networking/terraform.tfstate"
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
  vpc_id                    = data.terraform_remote_state.networking.outputs.vpc_id
  private_subnet_ids        = data.terraform_remote_state.networking.outputs.private_subnet_ids
  public_subnet_ids         = data.terraform_remote_state.networking.outputs.public_subnet_ids
  cluster_security_group_id = data.terraform_remote_state.networking.outputs.cluster_security_group_id
  argocd_security_group_id  = data.terraform_remote_state.networking.outputs.argocd_security_group_id
  secrets_access_policy_arn = data.terraform_remote_state.foundation.outputs.secrets_access_policy_arn
}