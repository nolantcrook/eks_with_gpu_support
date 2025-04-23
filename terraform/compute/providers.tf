provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
      Environment = var.environment
      stack       = "eks"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.eks_gpu.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks_gpu.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks_gpu.name, "--region", "us-west-2"]
    }
  }
}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks_gpu.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_gpu.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks_gpu.name, "--region", "us-west-2"]
  }
}
