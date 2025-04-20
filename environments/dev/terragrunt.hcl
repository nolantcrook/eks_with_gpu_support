remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = local.state_bucket
    key            = "${get_env("ENV", "dev")}/terraform/${basename(get_terragrunt_dir())}/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"


    # Add tags to the S3 bucket
    s3_bucket_tags = {
      Name        = "Terraform State Store"
      Environment = "dev"
      Terraform   = "true"
    }

    # Add DynamoDB table settings for state locking
    dynamodb_table_tags = {
      Name        = "Terraform State Lock Table"
      Environment = "dev"
      Terraform   = "true"
    }
  }
}

# Add a locals block to help with path construction
locals {
  # Parse the path relative to the git root
  relative_path = replace(
    path_relative_to_include(),
    "environments/${get_env("ENV", "dev")}",
    get_env("ENV", "dev")
  )
  state_bucket = "eks-stable-diffusion-terraform-state"
}


inputs = {
  environment = "dev"
  cluster_name = "eks-gpu-dev"
  instance_types = ["m6g.medium", "m6g.large"]
  state_bucket = local.state_bucket
  desired_nodes = 1
  max_nodes = 2
  min_nodes = 1
}
