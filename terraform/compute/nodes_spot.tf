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
    "m6a.2xlarge",
    "r5.large",
    "r5.xlarge",
    "r5a.large",
    "r5a.xlarge"
  ]

  scaling_config {
    desired_size = 2
    max_size     = 10
    min_size     = 2
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
    "k8s.io/cluster-autoscaler/eks-gpu-${var.environment}"    = "owned"
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
