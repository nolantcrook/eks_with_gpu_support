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

output "alb_security_group_id" {
  description = "Security group ID for alb"
  value       = aws_security_group.alb_security_group.id
}

output "eks_alb_dns_name" {
  description = "DNS name of the EKS ALB"
  value       = aws_lb.eks_alb.dns_name
}

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.hosted_zone_acm_certificate.arn
}

output "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.eks_alb.arn
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.eks_alb.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.eks_alb.dns_name
}
