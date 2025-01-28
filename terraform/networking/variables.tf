# variable "route53_zone_id" {
#   description = "Route53 hosted zone ID for DNS validation"
#   type        = string
# } 

variable "route53_zone_id_secret_arn" {
  description = "ARN of the Route53 Zone ID secret"
  type        = string
}

variable "environment" {
  description = "Environment name (dev or prod)"
  type        = string
}

variable "single_az_dev" {
  description = "Whether to use a single AZ in dev environment"
  type        = bool
  default     = true
} 