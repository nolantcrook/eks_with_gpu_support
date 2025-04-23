

variable "website_name" {
  description = "The name of the website"
  type        = string
}


variable "website_domain" {
  description = "The domain of the website"
  type        = string
}

variable "route53_zone_id" {
  description = "The ID of the Route53 zone"
  type        = string
}


variable "priority" {
  description = "The priority of the listener rule"
  type        = number
}

variable "alb_target_group_arn" {
  description = "The ARN of the ALB target group"
  type        = string
}

variable "alb_dns_name" {
  description = "The DNS name of the ALB"
  type        = string
}

variable "alb_zone_id" {
  description = "The zone ID of the ALB"
  type        = string
}

variable "listener_arn" {
  description = "The ARN of the listener"
  type        = string
}

variable "subdomain" {
  description = "The subdomain of the website"
  type        = string
}
