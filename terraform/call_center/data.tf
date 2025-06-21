data "terraform_remote_state" "rag" {
  backend = "s3"
  config = {
    bucket = "eks-stable-diffusion-terraform-state"
    key    = "${var.environment}/terraform/rag/terraform.tfstate"
    region = "us-west-2"
  }
}

locals {
  knowledge_base_id = data.terraform_remote_state.rag.outputs.knowledge_base_id
}
