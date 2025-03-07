output "alb_logs_bucket_arn" {
  description = "ARN of the ALB logs bucket"
  value       = aws_s3_bucket.alb_logs.arn
}

output "alb_logs_bucket_name" {
  description = "Name of the ALB logs bucket"
  value       = aws_s3_bucket.alb_logs.id
}

output "efs_file_system_id" {
  description = "ID of the EFS file system"
  value       = aws_efs_file_system.example.id
}
