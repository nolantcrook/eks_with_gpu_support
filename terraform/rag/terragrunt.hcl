include "env" {
  path = "${get_repo_root()}/environments/${get_env("ENV", "dev")}/terragrunt.hcl"
}


# Example configuration for auto-ingestion
inputs = {
  environment = get_env("ENV", "dev")
  # Enable auto-ingestion (default: true)
  auto_start_ingestion = true

  # Set timeout for large document sets (default: 30 minutes)
  ingestion_timeout_minutes = 45

  # Custom knowledge base name
  knowledge_base_name = "rag-knowledge-base-v3"

  # Additional tags
  tags = {
    Environment = get_env("ENV", "dev")
    Project     = "graphrag"
    Owner       = "data-team"
  }
}
