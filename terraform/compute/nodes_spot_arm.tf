resource "aws_eks_node_group" "arm_spot" {
  cluster_name    = aws_eks_cluster.eks_gpu.name
  node_group_name = "eks-arm-spot"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = local.private_subnet_ids
  capacity_type   = "SPOT"
  ami_type        = "AL2023_ARM_64_STANDARD"
  instance_types = [
    "a1.medium",
    "a1.large",
    "a1.xlarge",
    "a1.2xlarge",
    "a1.4xlarge",
    "m6g.medium",
    "m6g.large",
    "m6g.xlarge",
    "m6g.2xlarge",
    "m6g.4xlarge",
    "c6g.medium",
    "c6g.large",
    "c6g.xlarge",
    "c6g.2xlarge",
    "c6g.4xlarge",
    "r6g.medium",
    "r6g.large",
    "r6g.xlarge",
    "r6g.2xlarge",
    "r6g.4xlarge",
  ]

  scaling_config {
    desired_size = 1
    max_size     = 10
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    "lifecycle"                    = "Ec2Spot"
    "node.kubernetes.io/lifecycle" = "spot"
    "arch"                         = "arm64"
  }

  tags = {
    Name                                                      = "eks-arm-spot-${var.environment}"
    Environment                                               = var.environment
    "k8s.io/cluster-autoscaler/enabled"                       = "true"
    "k8s.io/cluster-autoscaler/node-template/label/lifecycle" = "Ec2Spot"
    "k8s.io/cluster-autoscaler/eks-gpu-${var.environment}"    = "owned"
    "arch"                                                    = "arm64"
  }

  launch_template {
    id      = aws_launch_template.spot.id
    version = aws_launch_template.spot.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKSManagedScalingPolicy
  ]
  taint {
    key    = "arch"
    value  = "arm64"
    effect = "NO_SCHEDULE"
  }
}


resource "aws_launch_template" "spot_arm" {
  name = "eks-node-group-spot-arm-${var.environment}"

  vpc_security_group_ids = [
    local.cluster_security_group_id,
    aws_eks_cluster.eks_gpu.vpc_config[0].cluster_security_group_id
  ]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name   = "eks-node-group-spot-arm-${var.environment}"
      "arch" = "arm64"
    }
  }
}
