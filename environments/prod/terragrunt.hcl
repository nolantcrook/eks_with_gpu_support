include "root" {
  path = find_in_parent_folders()
}

inputs = {
  environment = "prod"
  cluster_name = "eks-gpu-prod"
  instance_types = ["m6g.large", "m6g.xlarge"]
  desired_nodes = 2
  max_nodes = 4
  min_nodes = 2
} 