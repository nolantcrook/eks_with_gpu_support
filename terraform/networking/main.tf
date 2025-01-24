locals {
  azs = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "eks-gpu-vpc"
    "kubernetes.io/cluster/eks-gpu" = "shared"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count             = length(local.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = local.azs[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "eks-gpu-public-${local.azs[count.index]}"
    "kubernetes.io/cluster/eks-gpu" = "shared"
    "kubernetes.io/role/elb"        = "1"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = length(local.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = local.azs[count.index]

  tags = {
    Name = "eks-gpu-private-${local.azs[count.index]}"
    "kubernetes.io/cluster/eks-gpu" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "eks-gpu-igw"
  }
}

# NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "eks-gpu-nat"
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "eks-gpu-public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "eks-gpu-private"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security Groups
resource "aws_security_group" "cluster" {
  name_prefix = "eks-gpu-cluster-"
  description = "EKS cluster security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow all internal traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-gpu-cluster"
  }
}

# # ArgoCD Security Group
# resource "aws_security_group" "argocd" {
#   name_prefix = "eks-argocd-"
#   description = "Security group for ArgoCD server"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     description = "HTTPS from anywhere"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     description = "HTTP from anywhere (redirect to HTTPS)"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "eks-argocd"
#   }
# }

# resource "aws_wafv2_web_acl" "argocd" {
#   name        = "argocd-acl"
#   description = "WAF ACL for ArgoCD"
#   scope       = "REGIONAL"

#   default_action {
#     allow {}
#   }

#   rule {
#     name     = "AWSManagedRulesCommonRuleSet"
#     priority = 1

#     override_action {
#       none {}
#     }

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesCommonRuleSet"
#         vendor_name = "AWS"
#       }
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name               = "AWSManagedRulesCommonRuleSetMetric"
#       sampled_requests_enabled  = true
#     }
#   }

#   visibility_config {
#     cloudwatch_metrics_enabled = true
#     metric_name               = "ArgoCDWafAclMetric"
#     sampled_requests_enabled  = true
#   }
# }

# resource "aws_lb" "argocd" {
#   name               = "argocd-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.argocd.id]
#   subnets            = aws_subnet.public[*].id

#   tags = {
#     Name = "argocd-alb"
#   }
# }

# resource "aws_lb_target_group" "argocd" {
#   name        = "argocd-tg"
#   port        = 80
#   protocol    = "HTTP"
#   vpc_id      = aws_vpc.main.id
#   target_type = "ip"

#   health_check {
#     enabled             = true
#     healthy_threshold   = 2
#     interval            = 15
#     matcher            = "200-499"  # ArgoCD returns various status codes
#     path               = "/"
#     port               = "traffic-port"
#     timeout            = 5
#     unhealthy_threshold = 2
#   }
# }

# resource "aws_lb_listener" "argocd_https" {
#   load_balancer_arn = aws_lb.argocd.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = aws_acm_certificate.argocd.arn  # Use the created certificate

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.argocd.arn
#   }
# }

# resource "aws_wafv2_web_acl_association" "argocd" {
#   resource_arn = aws_lb.argocd.arn
#   web_acl_arn  = aws_wafv2_web_acl.argocd.arn
# }

# # Create ACM Certificate for ArgoCD
# resource "aws_acm_certificate" "argocd" {
#   domain_name       = "argocd.yourdomain.com"  # Replace with your domain
#   validation_method = "DNS"

#   tags = {
#     Name = "argocd-cert"
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# # Certificate validation
# resource "aws_acm_certificate_validation" "argocd" {
#   certificate_arn         = aws_acm_certificate.argocd.arn
#   validation_record_fqdns = [for record in aws_route53_record.argocd_validation : record.fqdn]
# }

# # DNS validation records
# resource "aws_route53_record" "argocd_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.argocd.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = var.route53_zone_id  # You'll need to add this variable
# }
