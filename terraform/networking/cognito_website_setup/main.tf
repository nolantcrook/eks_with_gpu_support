
# Add new Route53 record for 2048
resource "aws_route53_record" "website" {
  zone_id = var.route53_zone_id
  name    = "${var.website_name}.${var.website_domain}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Create a Cognito User Pool with email verification
resource "aws_cognito_user_pool" "website" {
  name = "${var.website_name}-user-pool"

  # Require email as the username
  username_attributes = ["email"]

  # Automatically verify email addresses
  auto_verified_attributes = ["email"]

  # Verification message template
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_message        = "Your verification code is {####}"
    email_subject        = "Verify your email for InvokeAI"
  }

  # Email configuration using Cognito's default email service
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }
}

# Create a Cognito App Client with a Client Secret
resource "aws_cognito_user_pool_client" "website" {
  name                                 = "${var.website_name}-app-client"
  user_pool_id                         = aws_cognito_user_pool.website.id
  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid"]
  callback_urls                        = ["https://${var.website_name}.${var.website_domain}/oauth2/idpresponse"]
  logout_urls                          = ["https://${var.website_name}.${var.website_domain}/logout"]
  supported_identity_providers         = ["COGNITO"]
}

# Create a Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "website" {
  domain       = "${var.website_name}-auth"
  user_pool_id = aws_cognito_user_pool.website.id
}

# Add listener rule for invokeai with Cognito authentication
resource "aws_lb_listener_rule" "website" {
  listener_arn = var.listener_arn
  priority     = var.priority

  action {
    type = "authenticate-cognito"
    authenticate_cognito {
      user_pool_arn       = aws_cognito_user_pool.website.arn
      user_pool_client_id = aws_cognito_user_pool_client.website.id
      user_pool_domain    = aws_cognito_user_pool_domain.website.domain
      session_cookie_name = "AWSELBAuthSessionCookie"
      scope               = "openid"
      session_timeout     = 3600
    }
  }

  action {
    type             = "forward"
    target_group_arn = var.alb_target_group_arn
  }

  condition {
    host_header {
      values = ["${var.website_name}.${var.website_domain}"]
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
