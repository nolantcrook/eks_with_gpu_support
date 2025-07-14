# GPU Nodes
module "gpu_nodes" {
  source = "./nodes_module"

  name          = "gpu-v3"
  cluster_name  = module.cluster.cluster_name
  environment   = var.environment
  node_role_arn = aws_iam_role.node.arn
  subnet_ids    = local.private_subnet_ids

  capacity_type  = "SPOT"
  ami_type       = "AL2023_x86_64_NVIDIA"
  instance_types = ["g4dn.xlarge", "g4dn.2xlarge", "g5.xlarge"]

  desired_size = 0
  min_size     = 0
  max_size     = 2

  taints = [{
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NO_SCHEDULE"
  }]

  additional_tags = {
    "k8s.io/cluster-autoscaler/node-template/resources/ephemeral-storage" = "53687091200"
    "k8s.io/cluster-autoscaler/node-template/resources/nvidia.com/gpu"    = "1"
    "node.kubernetes.io/gpu"                                              = "true"
  }

  additional_labels = {
    "node.kubernetes.io/gpu" = "true"
    "compute"                = "gpu"
  }

  security_group_ids = [
    local.cluster_security_group_id,
    module.cluster.cluster_security_group_id
  ]

  block_device_mappings = {
    device_name = "/dev/xvda"
    volume_size = 50
    volume_type = "gp2"
  }

  # node_group_depends_on = [
  #   aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
  #   aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
  #   aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
  # ]
}

# # ARM Spot Nodes
# module "arm_spot_nodes" {
#   source = "./nodes_module"

#   name          = "arm-spot"
#   cluster_name  = module.cluster.cluster_name
#   environment   = var.environment
#   node_role_arn = aws_iam_role.node.arn
#   subnet_ids    = local.private_subnet_ids

#   capacity_type = "SPOT"
#   ami_type      = "AL2023_ARM_64_STANDARD"
#   instance_types = [
#     "a1.medium", "a1.large", "a1.xlarge", "a1.2xlarge", "a1.4xlarge",
#     "m6g.medium", "m6g.large", "m6g.xlarge", "m6g.2xlarge", "m6g.4xlarge",
#     "c6g.medium", "c6g.large", "c6g.xlarge", "c6g.2xlarge", "c6g.4xlarge",
#     "r6g.medium", "r6g.large", "r6g.xlarge", "r6g.2xlarge", "r6g.4xlarge"
#   ]

#   desired_size = 1
#   min_size     = 1
#   max_size     = 10

#   taints = [{
#     key    = "arch"
#     value  = "arm64"
#     effect = "NO_SCHEDULE"
#   }]

#   additional_labels = {
#     "arch" = "arm64"
#   }

#   security_group_ids = [
#     local.cluster_security_group_id
#   ]
# }

# On-Demand x86 Nodes
module "x86_ondemand_nodes" {
  source        = "./nodes_module"
  ami_type      = "AL2023_x86_64_STANDARD"
  name          = "x86-ondemand-v3"
  cluster_name  = module.cluster.cluster_name
  environment   = var.environment
  node_role_arn = aws_iam_role.node.arn
  subnet_ids    = local.private_subnet_ids

  capacity_type = "ON_DEMAND"
  instance_types = [
    "t3.medium"
  ]

  desired_size = 0
  min_size     = 0
  max_size     = 1

  security_group_ids = [
    local.cluster_security_group_id,
    module.cluster.cluster_security_group_id
  ]
}

# Regular x86 Spot Nodes
module "x86_spot_nodes" {
  source        = "./nodes_module"
  ami_type      = "AL2023_x86_64_STANDARD"
  name          = "x86-spot-v3"
  cluster_name  = module.cluster.cluster_name
  environment   = var.environment
  node_role_arn = aws_iam_role.node.arn
  subnet_ids    = local.private_subnet_ids

  capacity_type = "SPOT"
  instance_types = ["t3.medium", "t3.large", "t3.xlarge", "t3.2xlarge"
  ]

  desired_size = 4
  min_size     = 3
  max_size     = 10

  security_group_ids = [
    local.cluster_security_group_id,
    module.cluster.cluster_security_group_id
  ]
}
