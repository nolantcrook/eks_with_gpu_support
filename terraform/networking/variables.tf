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

# Removing unused variables:
# - single_az_dev
# - create_multi_az_alb
# - node_asg_name