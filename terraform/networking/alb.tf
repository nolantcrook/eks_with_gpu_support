# ALB
resource "aws_lb" "eks_alb" {
  name               = "eks-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = aws_subnet.public[*].id

  access_logs {
    bucket  = split(":", local.alb_logs_bucket_arn)[5]
    enabled = true
  }

  idle_timeout = 300
  enable_http2 = true

  tags = {
    Name        = "eks-alb-${var.environment}"
    Environment = var.environment
  }
}

# Target group for ArgoCD
resource "aws_lb_target_group" "eks_alb" {
  name        = "eks-alb-${var.environment}"
  port        = 30080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }

  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "eks-alb-${var.environment}"
    Environment = var.environment
  }
}

# Add a dedicated target group for WebSocket connections
resource "aws_lb_target_group" "eks_alb_websocket" {
  name     = "eks-websocket-${var.environment}"
  port     = 30080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400 # 1 day
    enabled         = true
  }

  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200"
  }

  deregistration_delay = 60
}

# HTTP Listener (redirects to HTTPS)
resource "aws_lb_listener" "eks_alb_http" {
  load_balancer_arn = aws_lb.eks_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener
resource "aws_lb_listener" "eks_alb" {
  load_balancer_arn = aws_lb.eks_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.hosted_zone_acm_certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eks_alb.arn
  }

  depends_on = [
    aws_acm_certificate_validation.hosted_zone_acm_certificate_validation
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener_certificate" "additional_cert" {
  listener_arn    = aws_lb_listener.eks_alb.arn
  certificate_arn = aws_acm_certificate.hosted_zone_acm_certificate_pic.arn
}

resource "aws_lb_listener_certificate" "stratis_cert" {
  listener_arn    = aws_lb_listener.eks_alb.arn
  certificate_arn = aws_acm_certificate.hosted_zone_acm_certificate_stratis.arn

  depends_on = [
    aws_acm_certificate_validation.hosted_zone_acm_certificate_validation_stratis
  ]
}

resource "aws_lb_listener_certificate" "hauliday_cert" {
  listener_arn    = aws_lb_listener.eks_alb.arn
  certificate_arn = aws_acm_certificate.hosted_zone_acm_certificate_hauliday.arn

  depends_on = [
    aws_acm_certificate_validation.hosted_zone_acm_certificate_validation_hauliday
  ]
}

resource "aws_lb_listener_certificate" "tolby_cert" {
  listener_arn    = aws_lb_listener.eks_alb.arn
  certificate_arn = aws_acm_certificate.hosted_zone_acm_certificate_tolby.arn

  depends_on = [
    aws_acm_certificate_validation.hosted_zone_acm_certificate_validation_tolby
  ]
}

# Create a listener rule specifically for the WebSocket path
resource "aws_lb_listener_rule" "websocket_rule" {
  listener_arn = aws_lb_listener.eks_alb.arn
  priority     = 950 # Make sure this is unique and higher priority than the main rule

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eks_alb_websocket.arn
  }

  condition {
    host_header {
      values = ["dino-api.nolancrook.com"]
    }
  }

  # Match WebSocket paths
  condition {
    path_pattern {
      values = ["/socket.io/*", "/simple-ws*"]
    }
  }
}


resource "aws_lb_listener_rule" "umami_public_assets" {
  listener_arn = aws_lb_listener.eks_alb.arn
  priority     = 1495 # Higher priority than Cognito rule (1500) to bypass authentication

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eks_alb.arn
  }

  condition {
    host_header {
      values = ["analytics.nolancrook.com"]
    }
  }

  # Match Umami public assets that need to bypass authentication
  condition {
    path_pattern {
      values = [
        "/script.js",   # Main Umami tracking script
        "/umami.js",    # Alternative script name
        "/favicon.ico", # Favicon
        "/static/*",    # Static assets
      ]
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
