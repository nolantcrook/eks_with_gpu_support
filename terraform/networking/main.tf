resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "eks-gpu-${var.environment}"
    Environment = var.environment
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name                                               = "eks-gpu-public-${var.environment}-${var.availability_zones[count.index]}"
    Environment                                        = var.environment
    "kubernetes.io/cluster/eks-gpu-${var.environment}" = "shared"
    "kubernetes.io/role/elb"                           = "1"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                                               = "eks-gpu-private-${var.environment}-${var.availability_zones[count.index]}"
    Environment                                        = var.environment
    "kubernetes.io/cluster/eks-gpu-${var.environment}" = "shared"
    "kubernetes.io/role/internal-elb"                  = "1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "eks-gpu-${var.environment}"
    Environment = var.environment
  }
}

# EIP for NAT Gateway
resource "aws_eip" "nat" {
  count  = length(var.public_subnet_cidrs)
  domain = "vpc"

  tags = {
    Name        = "eks-gpu-nat-${var.environment}-${var.availability_zones[count.index]}"
    Environment = var.environment
  }
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  count         = length(var.public_subnet_cidrs)
  subnet_id     = aws_subnet.public[count.index].id
  allocation_id = aws_eip.nat[count.index].id

  tags = {
    Name        = "eks-gpu-${var.environment}-${var.availability_zones[count.index]}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "eks-gpu-public-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name        = "eks-gpu-private-${var.environment}-${var.availability_zones[count.index]}"
    Environment = var.environment
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Security Groups
resource "aws_security_group" "cluster" {
  name_prefix = "eks-gpu-cluster-${var.environment}"
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
    Name        = "eks-gpu-cluster-${var.environment}"
    Environment = var.environment
  }
}

# ArgoCD Security Group
resource "aws_security_group" "argocd" {
  name_prefix = "argocd-${var.environment}"
  description = "Security group for ArgoCD ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "argocd-${var.environment}"
    Environment = var.environment
  }
}

# Update cluster security group rules
resource "aws_security_group_rule" "nginx_ingress" {
  type                     = "ingress"
  from_port                = 30080
  to_port                  = 30080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.argocd.id
  security_group_id        = aws_security_group.cluster.id
  description              = "Allow ALB to NGINX Ingress"
}

# Allow internal traffic for NGINX (if not already defined elsewhere)
resource "aws_security_group_rule" "cluster_internal" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.cluster.id
  description              = "Allow internal cluster traffic"
}
