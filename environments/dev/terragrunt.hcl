include "root" {
  path = find_in_parent_folders()
}

inputs = {
  environment = "dev"
  cluster_name = "eks-gpu-dev"
  instance_types = ["m6g.medium", "m6g.large"]
  desired_nodes = 1
  max_nodes = 2
  min_nodes = 1
} 