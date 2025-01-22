include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path = "${dirname(find_in_parent_folders())}/../environments/${get_env("ENV", "dev")}/terragrunt.hcl"
} 