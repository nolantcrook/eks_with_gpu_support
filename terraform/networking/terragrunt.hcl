include "global_variables" {
  path = "${get_repo_root()}/environments/${get_env("ENV", "dev")}/terragrunt.hcl"
}



inputs = {
  environment = include.global_variables.inputs.environment
  state_bucket = include.global_variables.inputs.state_bucket
  vpc_cidr = "10.0.0.0/16"
  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
  private_subnet_cidrs = [
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]
  availability_zones = [
    "us-west-2a",
    "us-west-2b"
  ]
}
