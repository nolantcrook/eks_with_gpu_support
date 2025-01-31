# Certificate
resource "aws_acm_certificate" "argocd" {
  domain_name       = "argocd.hello-world-domain.com"
  validation_method = "DNS"

  tags = {
    Name = "argocd-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation record
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.argocd.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.route53_zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "argocd" {
  certificate_arn         = aws_acm_certificate.argocd.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# WAF IPSet for allowed IPs
resource "aws_wafv2_ip_set" "allowed_ips" {
  name               = "allowed-ips"
  description        = "Allowed IP addresses"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["76.129.127.17/32"] # Your IP from the security group
}

# WAF WebACL
resource "aws_wafv2_web_acl" "argocd" {
  name        = "argocd-waf"
  description = "WAF for ArgoCD ALB"
  scope       = "REGIONAL"

  default_action {
    block {}
  }

  rule {
    name     = "AllowedIPs"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allowed_ips.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowedIPsMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "ArgocdWafMetric"
    sampled_requests_enabled   = true
  }
}

# ALB for ArgoCD
resource "aws_lb" "argocd" {
  name               = "argocd-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.argocd.id]
  subnets            = aws_subnet.public[*].id

  access_logs {
    bucket  = split(":", var.alb_logs_bucket_arn)[5]
    enabled = true
  }

  tags = {
    Name        = "argocd-${var.environment}"
    Environment = var.environment
  }
}

# Target group for ArgoCD
resource "aws_lb_target_group" "argocd" {
  name        = "argocd-${var.environment}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

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

  tags = {
    Name        = "argocd-${var.environment}"
    Environment = var.environment
  }
}

# HTTP Listener (redirects to HTTPS)
resource "aws_lb_listener" "argocd_http" {
  load_balancer_arn = aws_lb.argocd.arn
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
resource "aws_lb_listener" "argocd" {
  load_balancer_arn = aws_lb.argocd.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.argocd.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.argocd.arn
  }
}

# Route53 record for ArgoCD
resource "aws_route53_record" "argocd" {
  zone_id = local.route53_zone_id
  name    = "argocd.hello-world-domain.com"
  type    = "A"

  alias {
    name                   = aws_lb.argocd.dns_name
    zone_id                = aws_lb.argocd.zone_id
    evaluate_target_health = true
  }
}

# WAF association with ALB
resource "aws_wafv2_web_acl_association" "argocd" {
  resource_arn = aws_lb.argocd.arn
  web_acl_arn  = aws_wafv2_web_acl.argocd.arn
}

# Update listener rule
resource "aws_lb_listener_rule" "argocd" {
  listener_arn = aws_lb_listener.argocd.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.argocd.arn
  }

  condition {
    host_header {
      values = ["argocd.hello-world-domain.com"]
    }
  }
}
