output "cluster_name" {
  value = aws_eks_cluster.eks_gpu.name
}

output "cluster_arn" {
  value = aws_eks_cluster.eks_gpu.arn
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.eks_gpu.vpc_config[0].cluster_security_group_id
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = aws_eks_cluster.eks_gpu.endpoint
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for EKS cluster logs"
  value       = aws_cloudwatch_log_group.eks_cluster_logs.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for EKS cluster logs"
  value       = aws_cloudwatch_log_group.eks_cluster_logs.name
}
