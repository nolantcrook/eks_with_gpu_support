# resource "aws_security_group" "bastion_sg" {
#   name        = "bastion-sg"
#   description = "Security group for bastion host"
#   vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = local.bastion_cidr_ranges
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# data "aws_ami" "amazon_linux_2" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["al2023-ami-*-x86_64"]
#   }
# }

# resource "aws_instance" "bastion" {
#   ami                    = data.aws_ami.amazon_linux_2.id
#   instance_type          = "t3.medium"
#   subnet_id              = data.terraform_remote_state.networking.outputs.public_subnet_ids[0]
#   vpc_security_group_ids = [aws_security_group.bastion_sg.id]
#   key_name               = local.key_pair_id // Add your SSH key name here
#   iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name

#   tags = {
#     Name = "BastionHost"
#   }
# }

# resource "aws_security_group_rule" "allow_ssh_from_bastion" {
#   type                     = "ingress"
#   from_port                = 22
#   to_port                  = 22
#   protocol                 = "tcp"
#   security_group_id        = local.cluster_security_group_id // Replace with your private instance security group ID
#   source_security_group_id = aws_security_group.bastion_sg.id
# }

# # IAM role for the bastion host
# resource "aws_iam_role" "bastion_role" {
#   name = "bastion-host-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })

#   tags = {
#     Name = "BastionHostRole"
#   }
# }

# # IAM policy for the bastion host
# resource "aws_iam_policy" "bastion_policy" {
#   name        = "bastion-host-policy"
#   description = "Policy for bastion host to access necessary AWS resources"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "ec2:DescribeInstances",
#           "ec2:DescribeSecurityGroups",
#           "ec2:DescribeSubnets",
#           "ec2:DescribeVpcs"
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       },
#       {
#         Action = [
#           "ssm:StartSession",
#           "ssm:TerminateSession",
#           "ssm:ResumeSession",
#           "ssm:DescribeSessions",
#           "ssm:GetConnectionStatus"
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       },
#       {
#         Action = [
#           "neptune-db:*",
#           "neptune:*"
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       },
#       {
#         Action = [
#           "es:*",
#           "aoss:*"
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       },
#       {
#         Action = [
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:ListBucket",
#           "s3:DeleteObject"
#         ]
#         Effect = "Allow"
#         Resource = [
#           "arn:aws:s3:::rag-uploads-891377073036",
#           "arn:aws:s3:::rag-uploads-891377073036/*"
#         ]
#       },
#       {
#         Action = [
#           "textract:StartDocumentTextDetection",
#           "textract:GetDocumentTextDetection"
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       },
#       {
#         Action = [
#           "bedrock:InvokeModel",
#           "bedrock:ListFoundationModels",
#           "bedrock:GetFoundationModel"
#         ]
#         Effect = "Allow"
#         Resource = [
#           "arn:aws:bedrock:us-west-2::foundation-model/amazon.titan-embed-text-v1",
#           "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"
#         ]
#       }
#     ]
#   })
# }

# # Attach the policy to the role
# resource "aws_iam_role_policy_attachment" "bastion_policy_attachment" {
#   role       = aws_iam_role.bastion_role.name
#   policy_arn = aws_iam_policy.bastion_policy.arn
# }

# # Create an instance profile for the bastion host
# resource "aws_iam_instance_profile" "bastion_profile" {
#   name = "bastion-host-profile"
#   role = aws_iam_role.bastion_role.name
# }
