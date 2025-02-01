data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "eks-stable-diffusion-terraform-state"
    key    = "${var.environment}/terraform/networking/terraform.tfstate"
    region = "us-west-2"
  }
}

data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket = "eks-stable-diffusion-terraform-state"
    key    = "${var.environment}/terraform/foundation/terraform.tfstate"
    region = "us-west-2"
  }
}

locals {
  private_subnet_ids        = data.terraform_remote_state.networking.outputs.private_subnet_ids
  public_subnet_ids         = data.terraform_remote_state.networking.outputs.public_subnet_ids
  cluster_security_group_id = data.terraform_remote_state.networking.outputs.cluster_security_group_id
  alb_target_group_arn      = data.terraform_remote_state.networking.outputs.alb_target_group_arn

  # Get ASG names from both node groups
  ondemand_asg_name = aws_eks_node_group.x86_ondemand.resources[0].autoscaling_groups[0].name
  spot_asg_name     = aws_eks_node_group.x86_spot.resources[0].autoscaling_groups[0].name
}

# Create attachments for both ASGs
resource "aws_autoscaling_attachment" "eks_ondemand_asg_attachment" {
  autoscaling_group_name = local.ondemand_asg_name
  lb_target_group_arn    = local.alb_target_group_arn
}

resource "aws_lb_target_group" "argocd" {
  name        = "argocd-${var.environment}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 15
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

resource "aws_autoscaling_attachment" "eks_spot_asg_attachment_spot" {
  autoscaling_group_name = local.spot_asg_name
  lb_target_group_arn    = aws_lb_target_group.argocd.arn
}

resource "aws_autoscaling_attachment" "eks_spot_asg_attachment_ondemand" {
  autoscaling_group_name = local.ondemand_asg_name
  lb_target_group_arn    = aws_lb_target_group.argocd.arn
}
