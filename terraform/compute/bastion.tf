resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "76.129.127.17/32",
      "136.36.32.17/32"
    ] // Replace with your IP address
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = data.terraform_remote_state.networking.outputs.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = local.ec2_ssh_key_pair_id // Add your SSH key name here

  tags = {
    Name = "BastionHost"
  }
}

resource "aws_security_group_rule" "allow_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = local.cluster_security_group_id // Replace with your private instance security group ID
  source_security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "allow_ssh_from_bastion_2" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_eks_cluster.eks_gpu.vpc_config[0].cluster_security_group_id // Replace with your private instance security group ID
  source_security_group_id = aws_security_group.bastion_sg.id
}
