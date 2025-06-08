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
  description = "Policy for SES email sending"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail",
          "ses:SendTemplatedEmail",
          "ses:SendBulkTemplatedEmail"
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
