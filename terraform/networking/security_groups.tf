# Security Groups
resource "aws_security_group" "argocd" {
  name        = "argocd-alb-${var.environment}"
  description = "Security group for ArgoCD ALB"
  vpc_id      = aws_vpc.main.id

  # HTTP ingress for redirect
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
      "76.129.127.17/32",
      "136.36.32.17/32"
    ]
    description = "Allow HTTP traffic for redirect"
  }

  # HTTPS ingress
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      "76.129.127.17/32",
      "136.36.32.17/32"
    ]
    description = "Allow HTTPS traffic"
  }

  egress {
    from_port       = 30080
    to_port         = 30080
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster.id]
    description     = "Allow outbound traffic to cluster on port 30080 only"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound HTTPS traffic"
  }


  egress {
    from_port       = 65535
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster.id]
    description     = "Allow outbound traffic to cluster on port 65535 only"
  }

  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound ICMP traffic for ping"
  }

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name        = "argocd-alb-${var.environment}"
    Environment = var.environment
  }
}

# Cluster Security Group
resource "aws_security_group" "cluster" {
  name        = "eks-cluster-sg-${var.environment}"
  description = "Security group for EKS cluster nodes"
  vpc_id      = aws_vpc.main.id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "eks-cluster-sg-${var.environment}"
    Environment = var.environment
  }
}

# Cluster internal traffic
resource "aws_security_group_rule" "cluster_internal" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.cluster.id
  description              = "Allow internal cluster traffic"
}

# ALB to NodePort (for NGINX Ingress)
resource "aws_security_group_rule" "alb_to_nginx" {
  type                     = "ingress"
  from_port                = 30080 # NGINX NodePort
  to_port                  = 30080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.argocd.id # ALB security group
  security_group_id        = aws_security_group.cluster.id
  description              = "Allow ALB to NGINX Ingress NodePort"
}

# ALB to NodePort (for NGINX Ingress)
resource "aws_security_group_rule" "alb_to_nginx_icmp" {
  type              = "ingress"
  from_port         = -1 # NGINX NodePort
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cluster.id
  description       = "Allow ALB to NGINX Ingress NodePort"
}

resource "aws_security_group_rule" "ssh_access" {
  type      = "ingress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"
  cidr_blocks = [
    "76.129.127.17/32",
    "136.36.32.17/32"
  ] // Replace with your actual IP address
  security_group_id = aws_security_group.cluster.id
  description       = "Allow SSH access from my IP"
}

# EFS Security Group
resource "aws_security_group" "efs" {
  name        = "efs-sg-${var.environment}"
  description = "Security group for EFS"
  vpc_id      = aws_vpc.main.id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "efs-sg-${var.environment}"
    Environment = var.environment
  }
}

# Allow EKS Cluster to access EFS
resource "aws_security_group_rule" "cluster_to_efs" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.efs.id
  description              = "Allow EKS Cluster to access EFS over NFS"
}

resource "aws_efs_mount_target" "example" {
  for_each        = { for idx, subnet_id in aws_subnet.private : idx => subnet_id }
  file_system_id  = local.efs_file_system_id
  subnet_id       = each.value.id
  security_groups = [aws_security_group.efs.id]
}
