

# Neptune Cluster
resource "aws_neptune_cluster" "main" {
  cluster_identifier                  = "rag-cluster"
  engine                              = "neptune"
  engine_version                      = var.neptune_engine_version
  backup_retention_period             = 7
  preferred_backup_window             = "03:00-04:00"
  skip_final_snapshot                 = true
  iam_database_authentication_enabled = true
  vpc_security_group_ids              = [local.neptune_security_group_id]
  tags                                = var.tags
}

resource "aws_neptune_cluster_instance" "cluster_instances" {
  count              = var.neptune_cluster_size
  cluster_identifier = aws_neptune_cluster.main.id
  engine             = "neptune"
  instance_class     = var.neptune_instance_class

  tags = var.tags
}

resource "aws_db_subnet_group" "neptune" {
  name       = "rag-neptune-subnet-group"
  subnet_ids = local.private_subnet_ids

  tags = var.tags
}

# OpenSearch Domain
resource "aws_opensearch_domain" "main" {
  domain_name    = "rag-domain"
  engine_version = var.opensearch_engine_version

  cluster_config {
    instance_type  = var.opensearch_instance_type
    instance_count = var.opensearch_instance_count
  }

  vpc_options {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = [local.opensearch_security_group_id]
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  tags = var.tags
}
