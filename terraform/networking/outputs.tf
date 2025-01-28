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