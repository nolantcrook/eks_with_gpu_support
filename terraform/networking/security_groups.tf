resource "aws_security_group_rule" "alb_to_argocd" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.argocd.id
  security_group_id        = aws_security_group.cluster.id
  description             = "Allow ALB health checks to ArgoCD server"
}

resource "aws_security_group_rule" "alb_to_nodes" {
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.argocd.id
  security_group_id        = aws_security_group.cluster.id
  description             = "Allow ALB traffic to NodePort range"
}

resource "aws_security_group_rule" "alb_to_cluster_egress" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.argocd_alb.id
  description             = "Allow ALB to send traffic to cluster"
} 