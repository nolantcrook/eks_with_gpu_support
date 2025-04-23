resource "aws_eks_node_group" "node_group" {
  cluster_name    = var.cluster_name
  node_group_name = "eks-${var.name}-${var.environment}"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  capacity_type   = var.capacity_type

  ami_type       = var.ami_type
  instance_types = var.instance_types

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  update_config {
    max_unavailable = 1
  }

  dynamic "taint" {
    for_each = var.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  labels = merge(
    {
      "lifecycle"                    = var.capacity_type == "SPOT" ? "Ec2Spot" : "OnDemand"
      "node.kubernetes.io/lifecycle" = lower(var.capacity_type)
    },
    var.additional_labels
  )

  tags = merge(
    {
      Name                                                      = "eks-${var.name}-${var.environment}"
      Environment                                               = var.environment
      "k8s.io/cluster-autoscaler/enabled"                       = "true"
      "k8s.io/cluster-autoscaler/node-template/label/lifecycle" = var.capacity_type == "SPOT" ? "Ec2Spot" : "OnDemand"
      "k8s.io/cluster-autoscaler/${var.cluster_name}"           = "owned"
    },
    var.additional_tags
  )

  launch_template {
    id      = aws_launch_template.node_template.id
    version = aws_launch_template.node_template.latest_version
  }

  depends_on = [var.node_group_depends_on]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "node_template" {
  name = "eks-${var.name}-${var.environment}"

  vpc_security_group_ids = var.security_group_ids

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings != null ? [var.block_device_mappings] : []
    content {
      device_name = block_device_mappings.value.device_name
      ebs {
        volume_size = block_device_mappings.value.volume_size
        volume_type = block_device_mappings.value.volume_type
      }
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      {
        Name = "eks-${var.name}-${var.environment}"
      },
      var.launch_template_tags
    )
  }
}
