variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "call-center"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "connect_instance_alias" {
  description = "Alias for the Amazon Connect instance"
  type        = string
  default     = "knowledge-base-connect"
}

variable "bedrock_model_id" {
  description = "Bedrock model ID for knowledge base queries"
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}



variable "claim_phone_number" {
  description = "Whether to claim a phone number for the Connect instance"
  type        = bool
  default     = false
}

variable "phone_number_country_code" {
  description = "Country code for the phone number"
  type        = string
  default     = "US"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "CallCenter"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
