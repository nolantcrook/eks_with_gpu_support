# Remote state data source
data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket = "hello-world-terraform-state"
    key    = "env:/${var.environment}/foundation/terraform.tfstate"
    region = "us-west-2"
  }
}

# Single locals block with all local values
locals {
  route53_zone_id = data.terraform_remote_state.foundation.outputs.route53_zone_id
}
