resource "aws_eks_node_group" "arm_gpu" {
  cluster_name    = aws_eks_cluster.eks_gpu.name
  node_group_name = "eks-arm-gpu"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = local.private_subnet_ids
  capacity_type   = "SPOT"
  ami_type        = "BOTTLEROCKET_ARM_64_NVIDIA"
  instance_types  = ["g5g.xlarge"] // ARM64 GPU instance

  scaling_config {
    desired_size = 0
    min_size     = 0
    max_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    "lifecycle"                    = "Ec2Spot"
    "node.kubernetes.io/lifecycle" = "spot"
    "node.kubernetes.io/gpu"       = "true"
    "arch"                         = "arm64"
  }

  tags = {
    Name                                                                  = "eks-arm-gpu-${var.environment}"
    Environment                                                           = var.environment
    "node.kubernetes.io/gpu"                                              = "true"
    "k8s.io/cluster-autoscaler/enabled"                                   = "true"
    "k8s.io/cluster-autoscaler/${var.environment}"                        = "owned"
    "k8s.io/cluster-autoscaler/node-template/label/lifecycle"             = "Ec2Spot"
    "k8s.io/cluster-autoscaler/node-template/resources/ephemeral-storage" = "53687091200"
    "k8s.io/cluster-autoscaler/node-template/resources/nvidia.com/gpu"    = "1"
    "arch"                                                                = "arm64"
  }

  launch_template {
    id      = aws_launch_template.arm_gpu.id
    version = aws_launch_template.arm_gpu.latest_version
  }

  taint {
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  taint {
    key    = "arch"
    value  = "arm64"
    effect = "NO_SCHEDULE"
  }
}

resource "aws_launch_template" "arm_gpu" {
  name = "eks-arm-gpu-node-group-${var.environment}"

  vpc_security_group_ids = [
    local.cluster_security_group_id,
    aws_eks_cluster.eks_gpu.vpc_config[0].cluster_security_group_id
  ]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name   = "eks-arm-gpu-node-group-${var.environment}"
      "arch" = "arm64"
    }
  }
}
