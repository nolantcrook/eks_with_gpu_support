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

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "graphrag"
  }
}
