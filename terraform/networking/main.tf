resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "eks-cluster-vpc-${var.environment}"
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
    Name                                               = "eks-public-subnet-${var.environment}-${var.availability_zones[count.index]}"
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
    Name                                               = "eks-private-subnet-${var.environment}-${var.availability_zones[count.index]}"
    Environment                                        = var.environment
    "kubernetes.io/cluster/eks-gpu-${var.environment}" = "shared"
    "kubernetes.io/role/internal-elb"                  = "1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "eks-ig-${var.environment}"
    Environment = var.environment
  }
}

# EIP for NAT Instance
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "eks-nat-${var.environment}"
    Environment = var.environment
  }
}

# Security Group for NAT Instance
resource "aws_security_group" "nat" {
  name_prefix = "nat-${var.environment}"
  vpc_id      = aws_vpc.main.id

  # Allow outbound traffic to internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound traffic from private subnets
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.private_subnet_cidrs
  }

  tags = {
    Name        = "nat-sg-${var.environment}"
    Environment = var.environment
  }
}

# Data source for NAT AMI
data "aws_ami" "nat" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# NAT Instance
resource "aws_instance" "nat" {
  ami                    = data.aws_ami.nat.id
  instance_type          = "t3.nano"               # Smallest instance type for cost savings
  subnet_id              = aws_subnet.public[0].id # Place in first public subnet
  vpc_security_group_ids = [aws_security_group.nat.id]
  source_dest_check      = false # Required for NAT instances
  key_name               = local.ec2_ssh_key_pair_id

  tags = {
    Name        = "eks-nat-${var.environment}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

# Associate EIP with NAT Instance
resource "aws_eip_association" "nat" {
  instance_id   = aws_instance.nat.id
  allocation_id = aws_eip.nat.id
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "eks-public-rt-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat.primary_network_interface_id
  }

  tags = {
    Name        = "eks-private-rt-${var.environment}-${var.availability_zones[count.index]}"
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
