// ... existing code ...

variable "environment" {
  description = "The environment for the EKS cluster (e.g., dev, prod)"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "Security group ID for the EKS cluster"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "sandbox_user" {
  description = "Sandbox user ARN"
  type        = string
  default     = "nolan"
}

variable "enabled_cluster_log_types" {
  description = "List of EKS cluster log types to enable. Options: api, audit, authenticator, controllerManager, scheduler"
  type        = list(string)
  default     = ["audit"]
  validation {
    condition = alltrue([
      for log_type in var.enabled_cluster_log_types :
      contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
    ])
    error_message = "Invalid log type. Must be one of: api, audit, authenticator, controllerManager, scheduler"
  }
}

# variable "cloudwatch_log_retention_days" {
#   description = "Number of days to retain CloudWatch logs for the EKS cluster"
#   type        = number
#   default     = 1
#   validation {
#     condition     = var.cloudwatch_log_retention_days >= 1 && var.cloudwatch_log_retention_days <= 3653
#     error_message = "Log retention must be between 1 and 3653 days"
#   }
# }
