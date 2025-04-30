
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

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 15
    matcher             = "200,302"
    path                = "/healthz"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "eks-alb-${var.environment}"
    Environment = var.environment
  }
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
