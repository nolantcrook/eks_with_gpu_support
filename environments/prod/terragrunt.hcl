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
    
    
    # Add tags to the S3 bucket (optional but recommended)
    s3_bucket_tags = {
      Name        = "Terraform State Store"
      Environment = "prod"
      Terraform   = "true"
    }
    
    
    # Add DynamoDB table settings for state locking
    dynamodb_table_tags = {
      Name        = "Terraform State Lock Table"
      Environment = "prod"
      Terraform   = "true"
    }
  }
}


inputs = {
  environment = "prod"
  cluster_name = "eks-gpu-prod"
  instance_types = ["m6g.large", "m6g.xlarge"]
  desired_nodes = 2
  max_nodes = 4
  min_nodes = 2
} 