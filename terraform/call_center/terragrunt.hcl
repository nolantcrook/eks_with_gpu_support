include "env" {
  path = "${get_repo_root()}/environments/${get_env("ENV", "dev")}/terragrunt.hcl"
}


# Example configuration for auto-ingestion
inputs = {
  environment = get_env("ENV", "dev")
  # Enable auto-ingestion (default: true)

}
