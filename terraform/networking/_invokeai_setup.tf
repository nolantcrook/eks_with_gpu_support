# Add Route53 record for invokeai
resource "aws_route53_record" "invokeai" {
  zone_id = local.route53_zone_id
  name    = "invokeai.hello-world-domain.com"
  type    = "A"

  alias {
    name                   = aws_lb.argocd.dns_name
    zone_id                = aws_lb.argocd.zone_id
    evaluate_target_health = true
  }
}

# Create a Cognito User Pool with email verification
resource "aws_cognito_user_pool" "invokeai" {
  name = "invokeai-user-pool"

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
resource "aws_cognito_user_pool_client" "invokeai" {
  name                                 = "invokeai-app-client"
  user_pool_id                         = aws_cognito_user_pool.invokeai.id
  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid"]
  callback_urls                        = ["https://invokeai.hello-world-domain.com/oauth2/idpresponse"]
  logout_urls                          = ["https://invokeai.hello-world-domain.com/logout"]
  supported_identity_providers         = ["COGNITO"]
}

# Create a Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "invokeai" {
  domain       = "invokeai-auth"
  user_pool_id = aws_cognito_user_pool.invokeai.id
}

# Add listener rule for invokeai with Cognito authentication
resource "aws_lb_listener_rule" "invokeai" {
  listener_arn = aws_lb_listener.argocd.arn
  priority     = 400

  action {
    type = "authenticate-cognito"
    authenticate_cognito {
      user_pool_arn       = aws_cognito_user_pool.invokeai.arn
      user_pool_client_id = aws_cognito_user_pool_client.invokeai.id
      user_pool_domain    = aws_cognito_user_pool_domain.invokeai.domain
      session_cookie_name = "AWSELBAuthSessionCookie"
      scope               = "openid"
      session_timeout     = 3600
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.argocd.arn
  }

  condition {
    host_header {
      values = ["invokeai.hello-world-domain.com"]
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
