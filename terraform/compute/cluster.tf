module "cluster" {
  source = "./cluster_module"

  environment               = var.environment
  cluster_name              = "eks-gpu"
  private_subnet_ids        = local.private_subnet_ids
  public_subnet_ids         = local.public_subnet_ids
  cluster_security_group_id = local.cluster_security_group_id
  sandbox_user              = "nolan"
}
