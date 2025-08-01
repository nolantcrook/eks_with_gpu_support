

data "terraform_remote_state" "storage" {
  backend = "s3"
  config = {
    bucket = "eks-stable-diffusion-terraform-state"
    key    = "${var.environment}/terraform/storage/terraform.tfstate"
    region = "us-west-2"
  }
}

data "aws_caller_identity" "current" {}

locals {
  rag_s3_bucket_arn = data.terraform_remote_state.storage.outputs.rag_s3_bucket_arn
}

# locals {
#   private_subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids
#   # ec2_ssh_key_pair_id       = data.terraform_remote_state.foundation.outputs.ec2_ssh_key_pair_id
#   # Get ASG names from both node groups
#   neptune_security_group_id    = data.terraform_remote_state.networking.outputs.neptune_security_group_id
#   opensearch_security_group_id = data.terraform_remote_state.networking.outputs.opensearch_security_group_id
# }
