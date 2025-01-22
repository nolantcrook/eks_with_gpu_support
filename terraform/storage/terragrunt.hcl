include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path = "${get_repo_root()}/environments/${get_env("ENV", "dev")}/terragrunt.hcl"
}

dependencies {
  paths = ["../foundation"]
} 