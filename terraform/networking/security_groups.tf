# ALB Security Group
resource "aws_security_group" "argocd" {
  name        = "argocd-${var.environment}"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  # HTTP ingress for redirect
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic for redirect"
  }

  # HTTPS ingress
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic"
  }

  # Allow all egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "alb-${var.environment}"
    Environment = var.environment
  }
}

# Cluster Security Group
resource "aws_security_group" "cluster" {
  name        = "eks-cluster-${var.environment}"
  description = "Security group for EKS cluster nodes"
  vpc_id      = aws_vpc.main.id

  # No direct ingress rules - all traffic must come through the ALB
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "eks-cluster-${var.environment}"
    Environment = var.environment
  }
}

# Allow ALB to reach NodePort
resource "aws_security_group_rule" "alb_to_nodeport" {
  type                     = "ingress"
  from_port                = 30080
  to_port                  = 30080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.argocd.id
  security_group_id        = aws_security_group.cluster.id
  description              = "Allow ALB to NodePort"
}

# Allow internal cluster communication
resource "aws_security_group_rule" "cluster_internal" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.cluster.id
  description       = "Allow internal cluster communication"
}
