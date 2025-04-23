
module "argocd_setup" {
  source               = "./cognito_website_setup"
  environment          = var.environment
  website_name         = "argocd"
  website_domain       = local.route53_zone_name
  route53_zone_id      = local.route53_zone_id
  priority             = 400
  alb_target_group_arn = aws_lb_target_group.eks_alb.arn
  alb_dns_name         = aws_lb.eks_alb.dns_name
  alb_zone_id          = aws_lb.eks_alb.zone_id
  listener_arn         = aws_lb_listener.eks_alb.arn
}

locals {
  website_setups = {
    game_2048 = {
      subdomain = "2048"
      source    = "./website_setup"
      priority  = 200
    }
    portfolio = {
      subdomain = "portfolio"
      source    = "./website_setup"
      priority  = 300
    }
    flask_api = {
      subdomain = "flask_api"
      source    = "./website_setup"
      priority  = 500
    }
  }
}

module "website_setups" {
  for_each             = local.website_setups
  source               = "./website_setup"
  website_name         = each.key
  subdomain            = each.value.subdomain
  website_domain       = local.route53_zone_name
  route53_zone_id      = local.route53_zone_id
  priority             = each.value.priority
  alb_target_group_arn = aws_lb_target_group.eks_alb.arn
  alb_dns_name         = aws_lb.eks_alb.dns_name
  alb_zone_id          = aws_lb.eks_alb.zone_id
  listener_arn         = aws_lb_listener.eks_alb.arn
}
