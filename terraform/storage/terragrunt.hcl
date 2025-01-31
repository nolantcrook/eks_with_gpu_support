include "env" {
  path = "${get_repo_root()}/environments/${get_env("ENV", "dev")}/terragrunt.hcl"
}

dependency "foundation" {
  config_path = "../foundation"
}

inputs = {
  environment = get_env("ENV", "dev")
}
