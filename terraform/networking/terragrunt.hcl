include "env" {
  path = "${get_repo_root()}/environments/${get_env("ENV", "dev")}/terragrunt.hcl"
}

dependency "foundation" {
  config_path = "../foundation"
}

dependency "storage" {
  config_path = "../storage"
}

inputs = {
  environment = get_env("ENV", "dev")
  route53_zone_id_secret_arn = dependency.foundation.outputs.route53_zone_id_secret_arn
  alb_logs_bucket_arn = dependency.storage.outputs.alb_logs_bucket_arn

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
}
