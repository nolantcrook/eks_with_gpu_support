include "env" {
  path = "${get_repo_root()}/environments/${get_env("ENV", "dev")}/terragrunt.hcl"
}

dependency "networking" {
  config_path = "../networking"
}

inputs = {
  environment = get_env("ENV", "dev")
  vpc_id = dependency.networking.outputs.vpc_id
  private_subnet_ids = dependency.networking.outputs.private_subnet_ids
  cluster_security_group_id = dependency.networking.outputs.cluster_security_group_id
} 