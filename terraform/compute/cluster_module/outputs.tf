output "cluster_name" {
  value = aws_eks_cluster.eks_gpu.name
}

output "cluster_arn" {
  value = aws_eks_cluster.eks_gpu.arn
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.eks_gpu.vpc_config[0].cluster_security_group_id
}
