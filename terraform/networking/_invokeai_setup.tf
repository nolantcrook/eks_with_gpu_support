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



# Add listener rule for invokeai
resource "aws_lb_listener_rule" "invokeai" {
  listener_arn = aws_lb_listener.argocd.arn
  priority     = 400

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
