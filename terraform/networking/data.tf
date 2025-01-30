# AWS Secrets Manager data sources
data "aws_secretsmanager_secret" "route53_zone_id" {
  arn = var.route53_zone_id_secret_arn
}

data "aws_secretsmanager_secret_version" "route53_zone_id" {
  secret_id = data.aws_secretsmanager_secret.route53_zone_id.id
}

# AWS Caller Identity
data "aws_caller_identity" "current" {}

locals {
  route53_zone_id = jsondecode(data.aws_secretsmanager_secret_version.route53_zone_id.secret_string)["zone_id"]
  cluster_name    = "eks-gpu-${var.environment}"  # Match the cluster name from compute/cluster.tf
}

# Get EKS node instances
data "aws_instances" "eks_nodes" {
  instance_tags = {
    "kubernetes.io/cluster/eks-gpu-${var.environment}" = "owned"
  }

  instance_state_names = ["running"]
} 