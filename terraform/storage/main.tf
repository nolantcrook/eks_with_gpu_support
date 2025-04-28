# ALB Logs Bucket
resource "aws_s3_bucket" "alb_logs" {
  bucket = "alb-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "alb-logs-${var.environment}"
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

# EFS File System
resource "aws_efs_file_system" "eks-efs" {
  creation_token = "example-efs-token"

  tags = {
    Name        = "eks-efs-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_efs_access_point" "eks-efs-ap" {
  file_system_id = aws_efs_file_system.eks-efs.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/deepseek"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 700
    }
  }

  tags = {
    Name        = "eks-efs-ap-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "efs_id" {
  name  = "/eks/efs-id"
  type  = "String"
  value = aws_efs_file_system.eks-efs.id
}

resource "aws_ssm_parameter" "efs_ap_id" {
  name  = "/eks/efs-ap-id"
  type  = "String"
  value = aws_efs_access_point.eks-efs-ap.id
}

# SQS Queue
resource "aws_sqs_queue" "api_queue" {
  name                       = "api-queue-${var.environment}"
  message_retention_seconds  = 1800 # 30 minutes
  visibility_timeout_seconds = 600  # 10 minutes

  tags = {
    Name        = "api-queue-${var.environment}"
    Environment = var.environment
  }
}

# EKS Bucket
resource "aws_s3_bucket" "eks_bucket" {
  bucket = "eks-bucket-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "eks-bucket-${data.aws_caller_identity.current.account_id}"
    Environment = var.environment
  }
}
