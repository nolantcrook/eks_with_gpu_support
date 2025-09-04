# Hauliday SES Email Identity
resource "aws_ses_email_identity" "hauliday" {
  email = "info@haulidayrentals.com" # Replace with your actual email
}

# SES Configuration Set for Hauliday
resource "aws_ses_configuration_set" "hauliday" {
  name = "hauliday-ses-config-set"

  delivery_options {
    tls_policy = "Require"
  }

  reputation_metrics_enabled = true
}

# SNS Topic for SMS notifications
resource "aws_sns_topic" "hauliday_sms" {
  name = "hauliday-sms-notifications"
}

# SNS Topics for Email Event Handling
resource "aws_sns_topic" "hauliday_email_bounces" {
  name = "hauliday-email-bounces"
}

resource "aws_sns_topic" "hauliday_email_complaints" {
  name = "hauliday-email-complaints"
}

# SES Event Destinations
resource "aws_ses_event_destination" "hauliday_bounces" {
  name                   = "hauliday-bounces-destination"
  configuration_set_name = aws_ses_configuration_set.hauliday.name
  enabled                = true
  matching_types         = ["bounce"]

  sns_destination {
    topic_arn = aws_sns_topic.hauliday_email_bounces.arn
  }
}

resource "aws_ses_event_destination" "hauliday_complaints" {
  name                   = "hauliday-complaints-destination"
  configuration_set_name = aws_ses_configuration_set.hauliday.name
  enabled                = true
  matching_types         = ["complaint"]

  sns_destination {
    topic_arn = aws_sns_topic.hauliday_email_complaints.arn
  }
}



# CloudWatch Log Group for Hauliday Notifications
resource "aws_cloudwatch_log_group" "hauliday_notifications" {
  name              = "/aws/hauliday/notifications"
  retention_in_days = 14
}

# Outputs
output "hauliday_ses_email_identity_arn" {
  description = "ARN of the Hauliday SES email identity"
  value       = aws_ses_email_identity.hauliday.arn
}

output "hauliday_ses_configuration_set_name" {
  description = "Name of the Hauliday SES configuration set"
  value       = aws_ses_configuration_set.hauliday.name
}

output "hauliday_sms_topic_arn" {
  description = "ARN of SNS topic for SMS notifications"
  value       = aws_sns_topic.hauliday_sms.arn
}
