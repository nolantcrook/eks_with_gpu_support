
module "argocd_setup" {
  source               = "./cognito_website_setup"
  website_name         = "argocd"
  website_domain       = local.route53_zone_name
  route53_zone_id      = local.route53_zone_id
  priority             = 400
  alb_target_group_arn = aws_lb_target_group.eks_alb.arn
  alb_dns_name         = aws_lb.eks_alb.dns_name
  alb_zone_id          = aws_lb.eks_alb.zone_id
  listener_arn         = aws_lb_listener.eks_alb.arn
}



module "agent_demo_setup" {
  source               = "./cognito_website_setup"
  website_name         = "agent-demo"
  website_domain       = local.route53_zone_name
  route53_zone_id      = local.route53_zone_id
  priority             = 450
  alb_target_group_arn = aws_lb_target_group.eks_alb.arn
  alb_dns_name         = aws_lb.eks_alb.dns_name
  alb_zone_id          = aws_lb.eks_alb.zone_id
  listener_arn         = aws_lb_listener.eks_alb.arn
}



module "tco_demo_setup" {
  source               = "./cognito_website_setup"
  website_name         = "tco-demo"
  website_domain       = local.route53_zone_name
  route53_zone_id      = local.route53_zone_id
  priority             = 1100
  alb_target_group_arn = aws_lb_target_group.eks_alb.arn
  alb_dns_name         = aws_lb.eks_alb.dns_name
  alb_zone_id          = aws_lb.eks_alb.zone_id
  listener_arn         = aws_lb_listener.eks_alb.arn
}

module "knowledgebase_demo_setup" {
  source               = "./cognito_website_setup"
  website_name         = "demo-knowledgebase"
  website_domain       = local.route53_zone_name
  route53_zone_id      = local.route53_zone_id
  priority             = 1200
  alb_target_group_arn = aws_lb_target_group.eks_alb.arn
  alb_dns_name         = aws_lb.eks_alb.dns_name
  alb_zone_id          = aws_lb.eks_alb.zone_id
  listener_arn         = aws_lb_listener.eks_alb.arn
}

module "umami_setup" {
  source               = "./cognito_website_setup"
  website_name         = "analytics"
  website_domain       = local.route53_zone_name
  route53_zone_id      = local.route53_zone_id
  priority             = 1500
  alb_target_group_arn = aws_lb_target_group.eks_alb.arn
  alb_dns_name         = aws_lb.eks_alb.dns_name
  alb_zone_id          = aws_lb.eks_alb.zone_id
  listener_arn         = aws_lb_listener.eks_alb.arn
}

locals {
  website_setups = {
    game_2048 = {
      subdomain        = "2048"
      source           = "./website_setup"
      priority         = 200
      target_group_arn = aws_lb_target_group.eks_alb.arn
    }
    portfolio = {
      subdomain        = "portfolio"
      source           = "./website_setup"
      priority         = 300
      target_group_arn = aws_lb_target_group.eks_alb.arn
    }
    flask_api = {
      subdomain        = "flask_api"
      source           = "./website_setup"
      priority         = 500
      target_group_arn = aws_lb_target_group.eks_alb.arn
    }
    deepseek = {
      subdomain        = "deepseek"
      source           = "./website_setup"
      priority         = 700
      target_group_arn = aws_lb_target_group.eks_alb.arn
    }
    dino_runner = {
      subdomain        = "dino-runner"
      source           = "./website_setup"
      priority         = 900
      target_group_arn = aws_lb_target_group.eks_alb.arn
    }
    dino_api = {
      subdomain        = "dino-api"
      source           = "./website_setup"
      priority         = 1000
      target_group_arn = aws_lb_target_group.eks_alb_websocket.arn
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



locals {
  pic_website_setups = {
    pic = {
      subdomain        = "pic"
      source           = "./website_setup"
      priority         = 800
      target_group_arn = aws_lb_target_group.eks_alb.arn
    }
  }
}

module "website_setups_pic" {
  for_each             = local.pic_website_setups
  source               = "./website_setup"
  website_name         = each.key
  subdomain            = each.value.subdomain
  website_domain       = local.route53_zone_name_pic
  route53_zone_id      = local.route53_zone_id_pic
  priority             = each.value.priority
  alb_target_group_arn = each.value.target_group_arn
  alb_dns_name         = aws_lb.eks_alb.dns_name
  alb_zone_id          = aws_lb.eks_alb.zone_id
  listener_arn         = aws_lb_listener.eks_alb.arn
}



locals {
  stratis_website_setups = {
    stratis = {
      subdomain        = "stratis"
      source           = "./website_setup"
      priority         = 1300
      target_group_arn = aws_lb_target_group.eks_alb.arn
    }
  }
}

module "website_setups_stratis" {
  for_each             = local.stratis_website_setups
  source               = "./website_setup"
  website_name         = each.key
  subdomain            = each.value.subdomain
  website_domain       = local.route53_zone_name_stratis
  route53_zone_id      = local.route53_zone_id_stratis
  priority             = each.value.priority
  alb_target_group_arn = each.value.target_group_arn
  alb_dns_name         = aws_lb.eks_alb.dns_name
  alb_zone_id          = aws_lb.eks_alb.zone_id
  listener_arn         = aws_lb_listener.eks_alb.arn
}


locals {
  hauliday_website_setups = {
    hauliday = {
      subdomain        = "hauliday"
      source           = "./website_setup"
      priority         = 1400
      target_group_arn = aws_lb_target_group.eks_alb.arn
    }
  }
}

module "website_setups_hauliday" {
  for_each             = local.hauliday_website_setups
  source               = "./website_setup"
  website_name         = each.key
  subdomain            = each.value.subdomain
  website_domain       = local.route53_zone_name_hauliday
  route53_zone_id      = local.route53_zone_id_hauliday
  priority             = each.value.priority
  alb_target_group_arn = each.value.target_group_arn
  alb_dns_name         = aws_lb.eks_alb.dns_name
  alb_zone_id          = aws_lb.eks_alb.zone_id
  listener_arn         = aws_lb_listener.eks_alb.arn
}


locals {
  tolby_website_setups = {
    tolby = {
      subdomain        = "tolby"
      source           = "./website_setup"
      priority         = 1600
      target_group_arn = aws_lb_target_group.eks_alb.arn
    }
  }
}

module "website_setups_tolby" {
  for_each             = local.tolby_website_setups
  source               = "./website_setup"
  website_name         = each.key
  subdomain            = each.value.subdomain
  website_domain       = local.route53_zone_name_tolby
  route53_zone_id      = local.route53_zone_id_tolby
  priority             = each.value.priority
  alb_target_group_arn = each.value.target_group_arn
  alb_dns_name         = aws_lb.eks_alb.dns_name
  alb_zone_id          = aws_lb.eks_alb.zone_id
  listener_arn         = aws_lb_listener.eks_alb.arn
}
