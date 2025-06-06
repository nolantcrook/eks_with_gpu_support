terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "2.3.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "opensearch" {
  url         = aws_opensearchserverless_collection.knowledge_base.collection_endpoint
  aws_region  = var.aws_region
  healthcheck = false
}
