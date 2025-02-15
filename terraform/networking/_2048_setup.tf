
# Add new Route53 record for 2048
resource "aws_route53_record" "game_2048" {
  zone_id = local.route53_zone_id
  name    = "2048.hello-world-domain.com"
  type    = "A"

  alias {
    name                   = aws_lb.argocd.dns_name
    zone_id                = aws_lb.argocd.zone_id
    evaluate_target_health = true
  }
}

# Add listener rule for 2048
resource "aws_lb_listener_rule" "game_2048" {
  listener_arn = aws_lb_listener.argocd.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.argocd.arn
  }

  condition {
    host_header {
      values = ["2048.hello-world-domain.com"]
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
