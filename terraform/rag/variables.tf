variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

# variable "environment" {
#   description = "Environment name (e.g., dev, prod)"
#   type        = string
#   default     = "dev"
# }

variable "knowledge_base_name" {
  description = "Name of the Bedrock knowledge base"
  type        = string
  default     = "rag-knowledge-base-v3"
}

variable "auto_start_ingestion" {
  description = "Whether to automatically start ingestion after knowledge base creation"
  type        = bool
  default     = true
}

variable "ingestion_timeout_minutes" {
  description = "Timeout for automatic ingestion in minutes"
  type        = number
  default     = 30
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "graphrag"
  }
}
variable "environment" {
  description = "Environment name (dev or prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
  default     = "rag-project"
}
