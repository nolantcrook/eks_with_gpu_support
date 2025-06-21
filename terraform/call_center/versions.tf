terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.2"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1"
    }
  }
}

# Configure AWS provider for us-west-2 region
provider "aws" {
  region = var.aws_region
}
