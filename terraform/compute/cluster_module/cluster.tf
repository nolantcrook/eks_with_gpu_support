resource "aws_eks_cluster" "eks_gpu" {
  name = "${var.cluster_name}-${var.environment}"

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.cluster.arn
  version  = "1.32"

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    security_group_ids      = [var.cluster_security_group_id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  # Enable managed node groups with configurable logging
  enabled_cluster_log_types = var.enabled_cluster_log_types

  # Add tags for spot instance management
  tags = {
    Environment                                                        = var.environment
    "k8s.io/cluster-autoscaler/enabled"                                = "true"
    "k8s.io/cluster-autoscaler/${var.cluster_name}-${var.environment}" = "owned"
  }

  # This ensures the cluster waits for node groups to be destroyed
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster
  ]
}

# CloudWatch Log Group for EKS cluster with configurable retention
# resource "aws_cloudwatch_log_group" "eks_cluster_logs" {
#   name              = "/aws/eks/${var.cluster_name}-${var.environment}/cluster"
#   retention_in_days = var.cloudwatch_log_retention_days

#   tags = {
#     Environment = var.environment
#     Cluster     = "${var.cluster_name}-${var.environment}"
#     Purpose     = "eks-cluster-logs"
#   }
# }

resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_policy" "efs_access" {
  name        = "EFSAccessPolicy"
  description = "IAM policy for accessing EFS"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeMountTargets",
          "elasticfilesystem:DescribeMountTargetSecurityGroups",
          "elasticfilesystem:CreateAccessPoint",
          "elasticfilesystem:DeleteAccessPoint",
          "elasticfilesystem:DescribeAccessPoints"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "efs_access_attach" {
  role       = aws_iam_role.cluster.name
  policy_arn = aws_iam_policy.efs_access.arn
}
