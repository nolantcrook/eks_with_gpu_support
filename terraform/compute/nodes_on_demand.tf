resource "aws_eks_node_group" "x86_ondemand" {
  cluster_name    = aws_eks_cluster.eks_gpu.name
  node_group_name = "eks-x86-ondemand"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = local.private_subnet_ids
  capacity_type   = "ON_DEMAND"
  instance_types = [
    "t3.medium",
    "t3.large",
    "t3.xlarge",
    "m5.large"
  ]

  scaling_config {
    desired_size = 0
    max_size     = 5
    min_size     = 0
  }

  update_config {
    max_unavailable = 1
  }


  launch_template {
    id      = aws_launch_template.ondemand.id
    version = aws_launch_template.ondemand.latest_version
  }

  tags = {
    Name                                                   = "eks-x86-ondemand-${var.environment}"
    Environment                                            = var.environment
    "k8s.io/cluster-autoscaler/enabled"                    = "true"
    "k8s.io/cluster-autoscaler/eks-gpu-${var.environment}" = "owned"
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKSManagedScalingPolicy
  ]
}

resource "aws_launch_template" "ondemand" {
  name = "eks-node-group-ondemand-${var.environment}"

  vpc_security_group_ids = [
    local.cluster_security_group_id,
    aws_eks_cluster.eks_gpu.vpc_config[0].cluster_security_group_id
  ]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "eks-node-group-ondemand-${var.environment}"
    }
  }
}
