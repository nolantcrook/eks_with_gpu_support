terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.84.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.6" // Specify the desired version constraint here
    }
  }
}
