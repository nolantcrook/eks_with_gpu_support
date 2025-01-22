remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "eks-stable-diffusion-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "us-west-2"
}
EOF
}

inputs = {
  environment = "prod"
  cluster_name = "eks-gpu-prod"
  instance_types = ["m6g.large", "m6g.xlarge"]
  desired_nodes = 2
  max_nodes = 4
  min_nodes = 2
} 