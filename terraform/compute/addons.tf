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

# Add AWS Load Balancer Controller addon
# resource "aws_eks_addon" "aws_load_balancer_controller" {
#   cluster_name = aws_eks_cluster.eks_gpu.name
#   addon_name   = "aws-load-balancer-controller"
#   addon_version = "v2.7.1-eksbuild.1"
# }

# Add Helm provider
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.eks_gpu.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks_gpu.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks_gpu.name]
    }
  }
}

# Install NGINX Ingress Controller
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "NodePort"
  }

  set {
    name  = "controller.service.targetPorts.http"
    value = "80"
  }

  set {
    name  = "controller.service.targetPorts.https"
    value = "443"
  }
}
