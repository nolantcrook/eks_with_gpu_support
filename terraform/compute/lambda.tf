# Lambda function for Hauliday notifications

variable "lambda_image_tag" {
  description = "Docker image tag for Lambda function"
  type        = string
  default     = "latest"
}
resource "aws_lambda_function" "hauliday_notifications" {
  function_name = "hauliday-notifications-${var.environment}"
  role          = aws_iam_role.hauliday_lambda_role.arn

  # Container image configuration
  package_type = "Image"
  image_uri    = "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-west-2.amazonaws.com/lambda_hauliday:${var.lambda_image_tag}"

  # Function configuration
  timeout     = 60
  memory_size = 512

  # Environment variables
  environment {
    variables = {
      ENVIRONMENT            = var.environment
      SNS_TOPIC_ARN          = aws_sns_topic.hauliday_notifications.arn
      SES_SOURCE_EMAIL       = "info@haulidayrentals.com"
      DYNAMODB_STREAM_MODE   = "enabled"
      RESERVATION_TABLE_NAME = local.hauliday_reservations_table_name
    }
  }

  # VPC configuration (optional - remove if Lambda doesn't need VPC access)
  # vpc_config {
  #   subnet_ids         = var.private_subnet_ids
  #   security_group_ids = [aws_security_group.lambda_sg.id]
  # }

  # Dead letter queue
  dead_letter_config {
    target_arn = aws_sqs_queue.hauliday_lambda_dlq.arn
  }

  tags = {
    Name        = "hauliday-notifications-${var.environment}"
    Environment = var.environment
    Purpose     = "hauliday-notifications"
  }

  depends_on = [
    aws_iam_role_policy_attachment.hauliday_lambda_policy_attachment,
    aws_cloudwatch_log_group.hauliday_lambda_logs,
  ]
}

# IAM Role for Lambda function
resource "aws_iam_role" "hauliday_lambda_role" {
  name = "hauliday-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "hauliday-lambda-role-${var.environment}"
    Environment = var.environment
  }
}

# IAM Policy for Lambda function
resource "aws_iam_policy" "hauliday_lambda_policy" {
  name        = "hauliday-lambda-policy-${var.environment}"
  description = "IAM policy for Hauliday Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudWatch Logs permissions
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:us-west-2:${data.aws_caller_identity.current.account_id}:*"
      },
      # SNS permissions
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
          "sns:SetSMSAttributes",
          "sns:GetSMSAttributes"
        ]
        Resource = [
          aws_sns_topic.hauliday_notifications.arn,
          "arn:aws:sns:us-west-2:${data.aws_caller_identity.current.account_id}:*"
        ]
      },
      # SES permissions
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail",
          "ses:SendTemplatedEmail",
          "ses:GetSendStatistics"
        ]
        Resource = "*"
      },
      # SQS permissions for DLQ
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.hauliday_lambda_dlq.arn
      },
      # DynamoDB Streams permissions
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeStream",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:ListStreams"
        ]
        Resource = local.hauliday_reservations_stream_arn
      },
      # ECR permissions for Lambda container image
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = [
          "arn:aws:ecr:us-west-2:${data.aws_caller_identity.current.account_id}:repository/lambda_hauliday"
        ]
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "hauliday_lambda_policy_attachment" {
  role       = aws_iam_role.hauliday_lambda_role.name
  policy_arn = aws_iam_policy.hauliday_lambda_policy.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "hauliday_lambda_logs" {
  name              = "/aws/lambda/hauliday-notifications-${var.environment}"
  retention_in_days = 14

  tags = {
    Name        = "hauliday-lambda-logs-${var.environment}"
    Environment = var.environment
  }
}

# SNS Topic for notifications
resource "aws_sns_topic" "hauliday_notifications" {
  name = "hauliday-notifications-${var.environment}"

  tags = {
    Name        = "hauliday-notifications-${var.environment}"
    Environment = var.environment
    Purpose     = "hauliday-sms-notifications"
  }
}

# Dead Letter Queue for failed Lambda executions
resource "aws_sqs_queue" "hauliday_lambda_dlq" {
  name = "hauliday-lambda-dlq-${var.environment}"

  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name        = "hauliday-lambda-dlq-${var.environment}"
    Environment = var.environment
    Purpose     = "lambda-dead-letter-queue"
  }
}

# DynamoDB Event Source Mapping for Lambda trigger
resource "aws_lambda_event_source_mapping" "hauliday_reservations_stream" {
  event_source_arn  = local.hauliday_reservations_stream_arn
  function_name     = aws_lambda_function.hauliday_notifications.arn
  starting_position = "LATEST"

  # Filter to only trigger on INSERT events (new reservations)
  filter_criteria {
    filter {
      pattern = jsonencode({
        eventName = ["INSERT"]
      })
    }
  }

  # Error handling
  maximum_batching_window_in_seconds = 5
  batch_size                         = 10
  parallelization_factor             = 1

  # Dead letter queue for failed stream processing
  destination_config {
    on_failure {
      destination_arn = aws_sqs_queue.hauliday_lambda_dlq.arn
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.hauliday_lambda_policy_attachment,
    aws_lambda_function.hauliday_notifications
  ]
}




# Outputs
output "hauliday_lambda_function_name" {
  description = "Name of the Hauliday Lambda function"
  value       = aws_lambda_function.hauliday_notifications.function_name
}

output "hauliday_lambda_function_arn" {
  description = "ARN of the Hauliday Lambda function"
  value       = aws_lambda_function.hauliday_notifications.arn
}

output "hauliday_sns_topic_arn" {
  description = "ARN of the Hauliday SNS topic"
  value       = aws_sns_topic.hauliday_notifications.arn
}

output "hauliday_event_source_mapping_uuid" {
  description = "UUID of the DynamoDB event source mapping"
  value       = aws_lambda_event_source_mapping.hauliday_reservations_stream.uuid
}
