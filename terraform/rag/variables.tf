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


# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "graphrag"
  }
}
