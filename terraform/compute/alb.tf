# ALB for ArgoCD
resource "aws_lb" "argocd" {
  name               = "argocd-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [local.argocd_security_group_id]
  subnets            = local.public_subnet_ids

  tags = {
    Name        = "argocd-alb"
    Environment = var.environment
  }
}

# Target Group for ArgoCD
resource "aws_lb_target_group" "argocd" {
  name        = "argocd-tg-${var.environment}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 15
    matcher            = "200-499"  # ArgoCD returns various status codes
    path               = "/"
    port               = "traffic-port"
    timeout            = 5
    unhealthy_threshold = 2
  }
}

# HTTP Listener
resource "aws_lb_listener" "argocd_http" {
  load_balancer_arn = aws_lb.argocd.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.argocd.arn
  }
}

# Output the ALB DNS name
output "argocd_alb_dns_name" {
  value = aws_lb.argocd.dns_name
} 