
# Add new Route53 record for 2048
resource "aws_route53_record" "website" {
  zone_id = var.route53_zone_id
  name    = "${var.subdomain}.${var.website_domain}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Add listener rule for 2048
resource "aws_lb_listener_rule" "website" {
  listener_arn = var.listener_arn
  priority     = var.priority

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
