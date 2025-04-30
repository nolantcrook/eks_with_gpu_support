
# ALB
resource "aws_lb" "eks_alb_pic" {
  name               = "eks-alb-${var.environment}-pic"
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



# HTTP Listener (redirects to HTTPS)
resource "aws_lb_listener" "eks_alb_http_pic" {
  load_balancer_arn = aws_lb.eks_alb_pic.arn
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
resource "aws_lb_listener" "eks_alb_pic" {
  load_balancer_arn = aws_lb.eks_alb_pic.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.hosted_zone_acm_certificate_pic.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eks_alb.arn
  }

  depends_on = [
    aws_acm_certificate_validation.hosted_zone_acm_certificate_validation_pic
  ]

  lifecycle {
    create_before_destroy = true
  }
}
