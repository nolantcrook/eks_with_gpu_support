data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "eks-stable-diffusion-terraform-state"
    key    = "${get_env("ENV", "dev")}/terraform/networking/terraform.tfstate"
    region = "us-west-2"
  }
}

locals {
  vpc_id                    = data.terraform_remote_state.networking.outputs.vpc_id
  private_subnet_ids        = data.terraform_remote_state.networking.outputs.private_subnet_ids
  cluster_security_group_id = data.terraform_remote_state.networking.outputs.cluster_security_group_id
}