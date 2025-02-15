resource "aws_eks_node_group" "x86_spot" {
  cluster_name    = aws_eks_cluster.eks_gpu.name
  node_group_name = "eks-x86-spot"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = local.private_subnet_ids
  capacity_type   = "SPOT"

  instance_types = [
    "t3.medium",
    "t3.large",
    "t3.xlarge",
    "t3.2xlarge",
    "t3a.medium",
    "t3a.large",
    "t3a.xlarge",
    "t3a.2xlarge",
    "m5.large",
    "m5.xlarge",
    "m5.2xlarge",
    "m5a.large",
    "m5a.xlarge",
    "m5a.2xlarge",
    "m6i.large",
    "m6i.xlarge",
    "m6i.2xlarge",
    "m6a.large",
    "m6a.xlarge",
    "m6a.2xlarge"
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
  }

  tags = {
    Name                                                      = "eks-x86-spot-${var.environment}"
    Environment                                               = var.environment
    "k8s.io/cluster-autoscaler/enabled"                       = "true"
    "k8s.io/cluster-autoscaler/node-template/label/lifecycle" = "Ec2Spot"
    "k8s.io/cluster-autoscaler/eku-gpu-${var.environment}"    = "owned"
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
}

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
    "k8s.io/cluster-autoscaler/eku-gpu-${var.environment}" = "owned"
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

resource "aws_launch_template" "spot" {
  name = "eks-node-group-spot-${var.environment}"

  vpc_security_group_ids = [
    local.cluster_security_group_id,
    aws_eks_cluster.eks_gpu.vpc_config[0].cluster_security_group_id
  ]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "eks-node-group-spot-${var.environment}"
    }
  }
}

resource "aws_launch_template" "gpu" {
  name = "eks-gpu-node-group-${var.environment}"

  vpc_security_group_ids = [
    local.cluster_security_group_id,
    aws_eks_cluster.eks_gpu.vpc_config[0].cluster_security_group_id
  ]

  # image_id = "ami-0c87233e00bd17f39"
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "eks-gpu-node-group-${var.environment}"
    }
  }
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
  policy_arn = data.terraform_remote_state.foundation.outputs.secrets_access_policy_arn
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSManagedScalingPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
  role       = aws_iam_role.node.name
}


# resource "aws_eks_node_group" "gpu_nodes" {
#   cluster_name    = aws_eks_cluster.eks_gpu.name
#   node_group_name = "eks-gpu-nodes"
#   node_role_arn   = aws_iam_role.node.arn
#   subnet_ids      = local.private_subnet_ids
#   capacity_type   = "ON_DEMAND"

#   instance_types = [
#     "g4ad.xlarge", # Choose a small but cost-effective GPU instance
#     "g4dn.xlarge"
#   ]

#   scaling_config {
#     desired_size = 1 # Start with 1 GPU node
#     min_size     = 1 # Allow scaling down to zero to save cost
#     max_size     = 3 # Scale up to 3 nodes based on demand
#   }

#   update_config {
#     max_unavailable = 1
#   }
#   launch_template {
#     id      = aws_launch_template.gpu.id
#     version = aws_launch_template.gpu.latest_version
#   }

#   # labels = {
#   #   "lifecycle"              = "spot"
#   #   "node.kubernetes.io/gpu" = "true"
#   # }

#   # tags = {
#   #   Name                                           = "eks-gpu-nodes-${var.environment}"
#   #   Environment                                    = var.environment
#   #   "k8s.io/cluster-autoscaler/enabled"            = "true"
#   #   "k8s.io/cluster-autoscaler/${var.environment}" = "owned"
#   # }

#   # taint {
#   #   key    = "nvidia.com/gpu"
#   #   value  = "true"
#   #   effect = "NO_SCHEDULE"
#   # }
# }
