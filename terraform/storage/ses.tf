# SES Email Identity
resource "aws_ses_email_identity" "example" {
  email = jsondecode(data.aws_secretsmanager_secret_version.ses_email.secret_string)["email"]
}

# SES Domain Identity (optional)
resource "aws_ses_domain_identity" "example" {
  count  = try(jsondecode(data.aws_secretsmanager_secret_version.ses_domain.secret_string)["domain"], "") != "" ? 1 : 0
  domain = jsondecode(data.aws_secretsmanager_secret_version.ses_domain.secret_string)["domain"]
}


# SES Domain DKIM
resource "aws_ses_domain_dkim" "example" {
  count  = try(jsondecode(data.aws_secretsmanager_secret_version.ses_domain.secret_string)["domain"], "") != "" ? 1 : 0
  domain = aws_ses_domain_identity.example[0].domain
}

# Route53 Records for Domain Verification and Email Authentication
data "aws_route53_zone" "domain" {
  count = try(jsondecode(data.aws_secretsmanager_secret_version.ses_domain.secret_string)["domain"], "") != "" ? 1 : 0
  name  = jsondecode(data.aws_secretsmanager_secret_version.ses_domain.secret_string)["domain"]
}

# SES Domain Verification TXT Record
resource "aws_route53_record" "ses_domain_verification" {
  count   = try(jsondecode(data.aws_secretsmanager_secret_version.ses_domain.secret_string)["domain"], "") != "" ? 1 : 0
  zone_id = data.aws_route53_zone.domain[0].zone_id
  name    = "_amazonses.${jsondecode(data.aws_secretsmanager_secret_version.ses_domain.secret_string)["domain"]}"
  type    = "TXT"
  ttl     = 300
  records = [aws_ses_domain_identity.example[0].verification_token]
}

# DKIM CNAME Records
resource "aws_route53_record" "ses_dkim_records" {
  count   = try(jsondecode(data.aws_secretsmanager_secret_version.ses_domain.secret_string)["domain"], "") != "" ? 3 : 0
  zone_id = data.aws_route53_zone.domain[0].zone_id
  name    = "${aws_ses_domain_dkim.example[0].dkim_tokens[count.index]}._domainkey.${jsondecode(data.aws_secretsmanager_secret_version.ses_domain.secret_string)["domain"]}"
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_ses_domain_dkim.example[0].dkim_tokens[count.index]}.dkim.amazonses.com"]
}

# SPF Record
resource "aws_route53_record" "spf" {
  count   = try(jsondecode(data.aws_secretsmanager_secret_version.ses_domain.secret_string)["domain"], "") != "" ? 1 : 0
  zone_id = data.aws_route53_zone.domain[0].zone_id
  name    = jsondecode(data.aws_secretsmanager_secret_version.ses_domain.secret_string)["domain"]
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 include:amazonses.com ~all"]
}

# DMARC Record
resource "aws_route53_record" "dmarc" {
  count   = try(jsondecode(data.aws_secretsmanager_secret_version.ses_domain.secret_string)["domain"], "") != "" ? 1 : 0
  zone_id = data.aws_route53_zone.domain[0].zone_id
  name    = "_dmarc.${jsondecode(data.aws_secretsmanager_secret_version.ses_domain.secret_string)["domain"]}"
  type    = "TXT"
  ttl     = 300
  records = ["v=DMARC1; p=quarantine; rua=mailto:dmarc-reports@${jsondecode(data.aws_secretsmanager_secret_version.ses_domain.secret_string)["domain"]}; ruf=mailto:dmarc-failures@${jsondecode(data.aws_secretsmanager_secret_version.ses_domain.secret_string)["domain"]}; fo=1"]
}

# SES Configuration Set
resource "aws_ses_configuration_set" "example" {
  name = "${var.project_name}-ses-config-set"

  delivery_options {
    tls_policy = "Require"
  }

  reputation_metrics_enabled = true
}

# SES Event Destination for CloudWatch
resource "aws_ses_event_destination" "cloudwatch" {
  name                   = "cloudwatch-destination"
  configuration_set_name = aws_ses_configuration_set.example.name
  enabled                = true
  matching_types         = ["send", "reject", "bounce", "complaint", "delivery"]

  cloudwatch_destination {
    default_value  = "default"
    dimension_name = "MessageTag"
    value_source   = "messageTag"
  }
}

# SNS Topics for Bounce and Complaint Handling
resource "aws_sns_topic" "ses_bounces" {
  name = "${var.project_name}-ses-bounces"
}

resource "aws_sns_topic" "ses_complaints" {
  name = "${var.project_name}-ses-complaints"
}

resource "aws_sns_topic" "ses_delivery" {
  name = "${var.project_name}-ses-delivery"
}

# SQS Queues for processing bounce and complaint notifications
resource "aws_sqs_queue" "ses_bounces_queue" {
  name                       = "${var.project_name}-ses-bounces-queue"
  message_retention_seconds  = 1209600 # 14 days
  visibility_timeout_seconds = 300
}

resource "aws_sqs_queue" "ses_complaints_queue" {
  name                       = "${var.project_name}-ses-complaints-queue"
  message_retention_seconds  = 1209600 # 14 days
  visibility_timeout_seconds = 300
}

resource "aws_sqs_queue" "ses_delivery_queue" {
  name                       = "${var.project_name}-ses-delivery-queue"
  message_retention_seconds  = 1209600 # 14 days
  visibility_timeout_seconds = 300
}

# SNS Topic Subscriptions to SQS Queues
resource "aws_sns_topic_subscription" "ses_bounces_sqs" {
  topic_arn = aws_sns_topic.ses_bounces.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.ses_bounces_queue.arn
}

resource "aws_sns_topic_subscription" "ses_complaints_sqs" {
  topic_arn = aws_sns_topic.ses_complaints.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.ses_complaints_queue.arn
}

resource "aws_sns_topic_subscription" "ses_delivery_sqs" {
  topic_arn = aws_sns_topic.ses_delivery.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.ses_delivery_queue.arn
}

# SQS Queue Policies to allow SNS to send messages
resource "aws_sqs_queue_policy" "ses_bounces_queue_policy" {
  queue_url = aws_sqs_queue.ses_bounces_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.ses_bounces_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.ses_bounces.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "ses_complaints_queue_policy" {
  queue_url = aws_sqs_queue.ses_complaints_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.ses_complaints_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.ses_complaints.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "ses_delivery_queue_policy" {
  queue_url = aws_sqs_queue.ses_delivery_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.ses_delivery_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.ses_delivery.arn
          }
        }
      }
    ]
  })
}

# SNS Event Destinations for SES Configuration Set
resource "aws_ses_event_destination" "sns_bounces" {
  name                   = "sns-bounces-destination"
  configuration_set_name = aws_ses_configuration_set.example.name
  enabled                = true
  matching_types         = ["bounce"]

  sns_destination {
    topic_arn = aws_sns_topic.ses_bounces.arn
  }
}

resource "aws_ses_event_destination" "sns_complaints" {
  name                   = "sns-complaints-destination"
  configuration_set_name = aws_ses_configuration_set.example.name
  enabled                = true
  matching_types         = ["complaint"]

  sns_destination {
    topic_arn = aws_sns_topic.ses_complaints.arn
  }
}

resource "aws_ses_event_destination" "sns_delivery" {
  name                   = "sns-delivery-destination"
  configuration_set_name = aws_ses_configuration_set.example.name
  enabled                = true
  matching_types         = ["delivery"]

  sns_destination {
    topic_arn = aws_sns_topic.ses_delivery.arn
  }
}

# CloudWatch Alarms for Bounce and Complaint Rate Monitoring
resource "aws_cloudwatch_metric_alarm" "high_bounce_rate" {
  alarm_name          = "${var.project_name}-high-bounce-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Bounce"
  namespace           = "AWS/SES"
  period              = "300"
  statistic           = "Average"
  threshold           = "5.0" # 5% bounce rate threshold
  alarm_description   = "This metric monitors SES bounce rate"
  alarm_actions       = [aws_sns_topic.ses_bounces.arn]

  dimensions = {
    ConfigurationSet = aws_ses_configuration_set.example.name
  }
}

resource "aws_cloudwatch_metric_alarm" "high_complaint_rate" {
  alarm_name          = "${var.project_name}-high-complaint-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Complaint"
  namespace           = "AWS/SES"
  period              = "300"
  statistic           = "Average"
  threshold           = "0.1" # 0.1% complaint rate threshold
  alarm_description   = "This metric monitors SES complaint rate"
  alarm_actions       = [aws_sns_topic.ses_complaints.arn]

  dimensions = {
    ConfigurationSet = aws_ses_configuration_set.example.name
  }
}

# Suppression List for Email Identity (handles bounces and complaints automatically)
resource "aws_sesv2_account_suppression_attributes" "example" {
  suppressed_reasons = ["BOUNCE", "COMPLAINT"]
}

# IAM Role for SES
resource "aws_iam_role" "ses_role" {
  name = "${var.project_name}-ses-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ses.amazonaws.com"
        }
      }
    ]
  })

}

# IAM Policy for SES sending
resource "aws_iam_policy" "ses_sending_policy" {
  name        = "${var.project_name}-ses-sending-policy"
  description = "Policy for SES email sending and bounce/complaint handling"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail",
          "ses:SendTemplatedEmail",
          "ses:SendBulkTemplatedEmail",
          "ses:GetSendQuota",
          "ses:GetSendStatistics",
          "ses:ListSuppressedDestinations",
          "ses:GetSuppressedDestination"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          aws_sns_topic.ses_bounces.arn,
          aws_sns_topic.ses_complaints.arn,
          aws_sns_topic.ses_delivery.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          aws_sqs_queue.ses_bounces_queue.arn,
          aws_sqs_queue.ses_complaints_queue.arn,
          aws_sqs_queue.ses_delivery_queue.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })

}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "ses_policy_attachment" {
  role       = aws_iam_role.ses_role.name
  policy_arn = aws_iam_policy.ses_sending_policy.arn
}

# SES Receipt Rule Set (for receiving emails)
resource "aws_ses_receipt_rule_set" "example" {
  count         = var.enable_ses_receiving ? 1 : 0
  rule_set_name = "${var.project_name}-receipt-rule-set"
}

# SES Receipt Rule
resource "aws_ses_receipt_rule" "example" {
  count         = var.enable_ses_receiving ? 1 : 0
  name          = "${var.project_name}-receipt-rule"
  rule_set_name = aws_ses_receipt_rule_set.example[0].rule_set_name
  recipients    = var.ses_recipients
  enabled       = true
  scan_enabled  = true

  s3_action {
    bucket_name = aws_s3_bucket.knowledge_base_data.bucket
    position    = 1
  }
}

# Output values
output "ses_email_identity_arn" {
  description = "ARN of the SES email identity"
  value       = aws_ses_email_identity.example.arn
}

output "ses_domain_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = try(jsondecode(data.aws_secretsmanager_secret_version.ses_domain.secret_string)["domain"], "") != "" ? aws_ses_domain_identity.example[0].arn : null
}

output "ses_configuration_set_name" {
  description = "Name of the SES configuration set"
  value       = aws_ses_configuration_set.example.name
}

output "ses_iam_role_arn" {
  description = "ARN of the SES IAM role"
  value       = aws_iam_role.ses_role.arn
}

output "ses_dkim_tokens" {
  description = "DKIM tokens for domain verification"
  value       = try(jsondecode(data.aws_secretsmanager_secret_version.ses_domain.secret_string)["domain"], "") != "" ? aws_ses_domain_dkim.example[0].dkim_tokens : []
}

# Bounce and Complaint Handling Outputs
output "ses_bounces_topic_arn" {
  description = "ARN of SNS topic for bounce notifications"
  value       = aws_sns_topic.ses_bounces.arn
}

output "ses_complaints_topic_arn" {
  description = "ARN of SNS topic for complaint notifications"
  value       = aws_sns_topic.ses_complaints.arn
}

output "ses_delivery_topic_arn" {
  description = "ARN of SNS topic for delivery notifications"
  value       = aws_sns_topic.ses_delivery.arn
}

output "ses_bounces_queue_url" {
  description = "URL of SQS queue for bounce processing"
  value       = aws_sqs_queue.ses_bounces_queue.url
}

output "ses_complaints_queue_url" {
  description = "URL of SQS queue for complaint processing"
  value       = aws_sqs_queue.ses_complaints_queue.url
}

output "ses_delivery_queue_url" {
  description = "URL of SQS queue for delivery confirmation processing"
  value       = aws_sqs_queue.ses_delivery_queue.url
}

output "ses_bounce_alarm_arn" {
  description = "ARN of CloudWatch alarm for high bounce rate"
  value       = aws_cloudwatch_metric_alarm.high_bounce_rate.arn
}

output "ses_complaint_alarm_arn" {
  description = "ARN of CloudWatch alarm for high complaint rate"
  value       = aws_cloudwatch_metric_alarm.high_complaint_rate.arn
}
