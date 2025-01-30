include "env" {
  path = "${get_repo_root()}/environments/${get_env("ENV", "dev")}/terragrunt.hcl"
}

dependency "foundation" {
  config_path = "../foundation"
}

inputs = {
  environment = get_env("ENV", "dev")
  route53_zone_id_secret_arn = dependency.foundation.outputs.route53_zone_id_secret_arn
  
  # Network configuration
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
  
  # ALB configuration
  create_multi_az_alb = get_env("ENV", "dev") == "prod" ? true : false
}