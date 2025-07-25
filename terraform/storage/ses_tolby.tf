# Tolby SES Email Identity
resource "aws_ses_email_identity" "tolby" {
  email = "nolan@tolby.co" # Replace with your actual email
}

# SES Configuration Set for Tolby
resource "aws_ses_configuration_set" "tolby" {
  name = "tolby-ses-config-set"

  delivery_options {
    tls_policy = "Require"
  }

  reputation_metrics_enabled = true
}

# SNS Topic for SMS notifications
resource "aws_sns_topic" "tolby_sms" {
  name = "tolby-sms-notifications"
}

# SNS Topics for Email Event Handling
resource "aws_sns_topic" "tolby_email_bounces" {
  name = "tolby-email-bounces"
}

resource "aws_sns_topic" "tolby_email_complaints" {
  name = "tolby-email-complaints"
}

# SES Event Destinations
resource "aws_ses_event_destination" "tolby_bounces" {
  name                   = "tolby-bounces-destination"
  configuration_set_name = aws_ses_configuration_set.tolby.name
  enabled                = true
  matching_types         = ["bounce"]

  sns_destination {
    topic_arn = aws_sns_topic.tolby_email_bounces.arn
  }
}

resource "aws_ses_event_destination" "tolby_complaints" {
  name                   = "tolby-complaints-destination"
  configuration_set_name = aws_ses_configuration_set.tolby.name
  enabled                = true
  matching_types         = ["complaint"]

  sns_destination {
    topic_arn = aws_sns_topic.tolby_email_complaints.arn
  }
}



# CloudWatch Log Group for Tolby Notifications
resource "aws_cloudwatch_log_group" "tolby_notifications" {
  name              = "/aws/tolby/notifications"
  retention_in_days = 14
}

# Outputs
output "tolby_ses_email_identity_arn" {
  description = "ARN of the Tolby SES email identity"
  value       = aws_ses_email_identity.tolby.arn
}

output "tolby_ses_configuration_set_name" {
  description = "Name of the Tolby SES configuration set"
  value       = aws_ses_configuration_set.tolby.name
}

output "tolby_sms_topic_arn" {
  description = "ARN of SNS topic for SMS notifications"
  value       = aws_sns_topic.tolby_sms.arn
}
