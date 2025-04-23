output "cluster_name" {
  value = aws_eks_cluster.eks_gpu.name
}

output "cluster_arn" {
  value = aws_eks_cluster.eks_gpu.arn
}
