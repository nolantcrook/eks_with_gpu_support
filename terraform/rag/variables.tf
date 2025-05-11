variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

# Neptune Variables
variable "neptune_instance_class" {
  description = "Instance class for Neptune cluster"
  type        = string
  default     = "db.r5.large"
}

variable "neptune_cluster_size" {
  description = "Number of instances in Neptune cluster"
  type        = number
  default     = 1
}

variable "neptune_engine_version" {
  description = "Neptune engine version"
  type        = string
  default     = "1.2.0.2"
}

# OpenSearch Variables
variable "opensearch_instance_type" {
  description = "Instance type for OpenSearch domain"
  type        = string
  default     = "t3.small.search"
}

variable "opensearch_instance_count" {
  description = "Number of instances in OpenSearch domain"
  type        = number
  default     = 1
}

variable "opensearch_engine_version" {
  description = "OpenSearch engine version"
  type        = string
  default     = "OpenSearch_2.5"
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
