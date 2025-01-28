locals {
  all_azs = ["us-west-2a", "us-west-2b", "us-west-2c"]
  # Use single AZ for dev, all AZs for prod
  azs = var.environment == "dev" && var.single_az_dev ? ["us-west-2a"] : local.all_azs
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

# ArgoCD Security Group
resource "aws_security_group" "argocd" {
  name_prefix = "eks-argocd-"
  description = "Security group for ArgoCD server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from anywhere (WAF handles IP restriction)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # WAF will restrict to your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-argocd"
  }
}

# Update cluster security group rules
resource "aws_security_group_rule" "nginx_ingress" {
  type                     = "ingress"
  from_port               = 30080
  to_port                 = 30080
  protocol                = "tcp"
  source_security_group_id = aws_security_group.argocd.id
  security_group_id       = aws_security_group.cluster.id
  description             = "Allow ALB to NGINX Ingress"
}

# Allow internal traffic for NGINX (if not already defined elsewhere)
resource "aws_security_group_rule" "cluster_internal" {
  type                     = "ingress"
  from_port               = 0
  to_port                 = 65535
  protocol                = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id       = aws_security_group.cluster.id
  description             = "Allow internal cluster traffic"
}