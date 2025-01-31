output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "cluster_security_group_id" {
  description = "Security group ID for the cluster"
  value       = aws_security_group.cluster.id
}

output "argocd_security_group_id" {
  description = "Security group ID for ArgoCD"
  value       = aws_security_group.argocd.id
}

output "argocd_alb_dns_name" {
  description = "DNS name of the ArgoCD ALB"
  value       = aws_lb.argocd.dns_name
}

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.argocd.arn
}

output "waf_acl_arn" {
  description = "ARN of the WAF ACL"
  value       = aws_wafv2_web_acl.argocd.arn
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.argocd.id
}

resource "aws_ssm_parameter" "argocd_ingress_params" {
  name  = "/eks/${var.environment}/argocd/ingress"
  type  = "SecureString"
  value = jsonencode({
    certificate_arn      = aws_acm_certificate.argocd.arn
    waf_acl_arn         = aws_wafv2_web_acl.argocd.arn
    alb_security_group_id = aws_security_group.argocd.id
  })
} 