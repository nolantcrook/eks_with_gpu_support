variable "environment" {
  description = "Environment name (dev or prod)"
  type        = string
}

# SES Variables
variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
  default     = "rag-project"
}

variable "enable_ses_receiving" {
  description = "Whether to enable SES email receiving functionality"
  type        = bool
  default     = false
}

variable "ses_recipients" {
  description = "List of email recipients for SES receipt rules"
  type        = list(string)
  default     = []
}
