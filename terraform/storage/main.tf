# ALB Logs Bucket
resource "aws_s3_bucket" "alb_logs" {
  bucket = "argocd-alb-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "argocd-alb-logs-${var.environment}"
    Environment = var.environment
  }
}

# ALB Logs Bucket Policy
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action = "s3:PutObject"
        Resource = [
          "${aws_s3_bucket.alb_logs.arn}/*"
        ]
      }
    ]
  })
}

# Enable versioning for the ALB logs bucket
resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access to the ALB logs bucket
resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "main" {}

# EFS File System
resource "aws_efs_file_system" "example" {
  creation_token = "example-efs-token"

  tags = {
    Name        = "invokeai-efs-${var.environment}"
    Environment = var.environment
  }
}

# SQS Queue
resource "aws_sqs_queue" "invokeai_api_queue" {
  name                       = "invokeai-api-queue-${var.environment}"
  message_retention_seconds  = 1800 # 30 minutes
  visibility_timeout_seconds = 600  # 10 minutes

  tags = {
    Name        = "example-queue-${var.environment}"
    Environment = var.environment
  }
}
