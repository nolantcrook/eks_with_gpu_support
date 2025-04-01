

resource "aws_eks_node_group" "gpu_nodes" {
  cluster_name    = aws_eks_cluster.eks_gpu.name
  node_group_name = "eks-gpu-nodes-v6"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = local.private_subnet_ids
  capacity_type   = "SPOT"
  lifecycle {
    create_before_destroy = true
  }
  ami_type = "AL2023_x86_64_NVIDIA"
  instance_types = [ # Choose a small but cost-effective GPU instance
    "g4dn.xlarge",
    "g4dn.2xlarge",
    "g5.xlarge"
  ]

  scaling_config {
    desired_size = 0 # Start with 1 GPU node
    min_size     = 0 # Allow scaling down to zero to save cost
    max_size     = 2 # Scale up to 3 nodes based on demand
  }

  update_config {
    max_unavailable = 1
  }
  launch_template {
    id      = aws_launch_template.gpu.id
    version = aws_launch_template.gpu.latest_version
  }

  labels = {
    "lifecycle"                    = "Ec2Spot"
    "node.kubernetes.io/lifecycle" = "spot"
    "node.kubernetes.io/gpu"       = "true"
    "compute"                      = "gpu"
  }

  tags = {
    Name                                                                  = "eks-gpu-nodes-${var.environment}"
    Environment                                                           = var.environment
    "node.kubernetes.io/gpu"                                              = "true"
    "k8s.io/cluster-autoscaler/enabled"                                   = "true"
    "k8s.io/cluster-autoscaler/${var.environment}"                        = "owned"
    "k8s.io/cluster-autoscaler/node-template/label/lifecycle"             = "Ec2Spot"
    "k8s.io/cluster-autoscaler/node-template/resources/ephemeral-storage" = "53687091200"
    "k8s.io/cluster-autoscaler/node-template/resources/nvidia.com/gpu"    = "1"
  }

  taint {
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NO_SCHEDULE"
  }
}


resource "aws_launch_template" "gpu" {
  name = "eks-gpu-node-group-${var.environment}"

  vpc_security_group_ids = [
    local.cluster_security_group_id,
    aws_eks_cluster.eks_gpu.vpc_config[0].cluster_security_group_id
  ]
  # image_id = "ami-0c87233e00bd17f39"
  key_name = local.ec2_ssh_key_pair_id
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 50    # Size in GiB, adjust as needed
      volume_type = "gp2" # General Purpose SSD
    }
  }


  tag_specifications {
    resource_type = "instance"
    tags = {
      Name                                                                     = "eks-gpu-node-group-${var.environment}"
      compute                                                                  = "gpu"
      "k8s.io/cluster-autoscaler/node-template/resources/ephemeral-storage"    = "53687091200" # 50 GiB in bytes
      "k8s.io/cluster-autoscaler/node-template/resources/nvidia.com/gpu"       = "1"
      "k8s.io/cluster-autoscaler/node-template/resources/nvidia.com/gpu.count" = "1"
    }
  }
}
