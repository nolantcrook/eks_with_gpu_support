data "aws_caller_identity" "current" {}

locals {
  account_id   = data.aws_caller_identity.current.account_id
  sandbox_user = "arn:aws:iam::${local.account_id}:user/nolan"
}

resource "aws_eks_access_entry" "eks_gpu_workshop" {
  cluster_name  = aws_eks_cluster.eks_gpu.name
  principal_arn = "local.sandbox_user"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "eks_gpu_workshop" {
  cluster_name  = aws_eks_cluster.eks_gpu.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = local.sandbox_user

  access_scope {
    type = "cluster"
  }
}
