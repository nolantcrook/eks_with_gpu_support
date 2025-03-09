

resource "aws_route53_record" "invokeai-api" {
  zone_id = local.route53_zone_id
  name    = "invokeai-api.hello-world-domain.com"
  type    = "A"

  alias {
    name                   = aws_lb.argocd.dns_name
    zone_id                = aws_lb.argocd.zone_id
    evaluate_target_health = true
  }
}


resource "aws_lb_listener_rule" "invokeai-api" {
  listener_arn = aws_lb_listener.argocd.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.argocd.arn
  }

  condition {
    host_header {
      values = ["invokeai-api.hello-world-domain.com"]
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
