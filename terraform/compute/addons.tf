resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = aws_eks_cluster.eks_gpu.name
  addon_name    = "vpc-cni"
  addon_version = "v1.19.2-eksbuild.1"
}

resource "aws_eks_addon" "coredns" {
  cluster_name  = aws_eks_cluster.eks_gpu.name
  addon_name    = "coredns"
  addon_version = "v1.11.4-eksbuild.2"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name  = aws_eks_cluster.eks_gpu.name
  addon_name    = "kube-proxy"
  addon_version = "v1.31.3-eksbuild.2"
}

resource "aws_eks_addon" "metrics_server" {
  cluster_name  = aws_eks_cluster.eks_gpu.name
  addon_name    = "metrics-server"
  addon_version = "v0.7.2-eksbuild.1"
}

resource "aws_eks_addon" "pod_identity" {
  cluster_name  = aws_eks_cluster.eks_gpu.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = "v1.3.4-eksbuild.1"
}

# No AWS Load Balancer Controller needed since:
# 1. ALB is managed by Terraform
# 2. Traffic routes directly to NGINX ingress NodePort
# 3. NGINX ingress handles internal service routing

resource "aws_eks_addon" "efs_csi_driver" {
  cluster_name  = aws_eks_cluster.eks_gpu.name
  addon_name    = "efs-csi-driver"
  addon_version = "v2.1.6"
}
