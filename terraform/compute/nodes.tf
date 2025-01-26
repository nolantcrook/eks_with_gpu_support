resource "aws_eks_node_group" "arm" {
  cluster_name    = aws_eks_cluster.eks_gpu.name
  node_group_name = "eks-arm-1"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = local.private_subnet_ids
  ami_type        = "AL2_ARM_64"
  capacity_type   = "SPOT"
  
  instance_types = [
    "t4g.medium",
    "m6g.large",
    "m6g.xlarge",
    "m6g.2xlarge"
  ]

  scaling_config {
    desired_size = 2
    max_size     = 10
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    lifecycle = "Ec2Spot"
    aws.amazon.com/spot = "true"
  }

  taint {
    key    = "spot"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  tags = {
    Name        = "eks-arm-${var.environment}"
    Environment = var.environment
    "k8s.io/cluster-autoscaler/enabled" = "true"
    "k8s.io/cluster-autoscaler/node-template/label/lifecycle" = "Ec2Spot"
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_secrets_access,
  ]
}

resource "aws_eks_node_group" "x86" {
  cluster_name    = aws_eks_cluster.eks_gpu.name
  node_group_name = "eks-x86-1"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = local.private_subnet_ids
  capacity_type   = "SPOT"
  
  instance_types = [
    "t3.medium",
    "t3.large",
    "t3.xlarge",
    "m5.large"
  ]

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    lifecycle = "Ec2Spot"
    aws.amazon.com/spot = "true"
  }

  taint {
    key    = "spot"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  tags = {
    Name        = "eks-x86-${var.environment}"
    Environment = var.environment
    "k8s.io/cluster-autoscaler/enabled" = "true"
    "k8s.io/cluster-autoscaler/node-template/label/lifecycle" = "Ec2Spot"
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_secrets_access,
  ]
}

resource "aws_iam_role" "node" {
  name = "eks-node-role-${var.environment}"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_secrets_access" {
  policy_arn = local.secrets_access_policy_arn
  role       = aws_iam_role.node.name
}
