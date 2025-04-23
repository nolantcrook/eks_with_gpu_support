variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "name" {
  description = "Name of the node group"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the IAM role for nodes"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the node group"
  type        = list(string)
}

variable "capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group"
  type        = string
  default     = "AL2023_x86_64"
}

variable "instance_types" {
  description = "List of instance types associated with the EKS Node Group"
  type        = list(string)
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
}

variable "taints" {
  description = "List of Kubernetes taints to apply to nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

variable "additional_labels" {
  description = "Additional Kubernetes labels to apply to nodes"
  type        = map(string)
  default     = {}
}

variable "additional_tags" {
  description = "Additional tags for the node group"
  type        = map(string)
  default     = {}
}

variable "security_group_ids" {
  description = "List of security group IDs for the node group"
  type        = list(string)
}

variable "block_device_mappings" {
  description = "Block device mappings for the launch template"
  type = object({
    device_name = string
    volume_size = number
    volume_type = string
  })
  default = null
}

variable "launch_template_tags" {
  description = "Additional tags for the launch template"
  type        = map(string)
  default     = {}
}

variable "node_group_depends_on" {
  description = "List of resources the node group depends on"
  type        = list(any)
  default     = []
}
