data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "hello-world-terraform-state"
    key    = "env:/${var.environment}/networking/terraform.tfstate"
    region = "us-west-2"
  }
}

data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket = "hello-world-terraform-state"
    key    = "env:/${var.environment}/foundation/terraform.tfstate"
    region = "us-west-2"
  }
}

locals {
  private_subnet_ids        = data.terraform_remote_state.networking.outputs.private_subnet_ids
  public_subnet_ids         = data.terraform_remote_state.networking.outputs.public_subnet_ids
  cluster_security_group_id = data.terraform_remote_state.networking.outputs.cluster_security_group_id
}
