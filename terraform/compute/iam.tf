resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "ClusterAutoscalerPolicy"
  description = "IAM policy for Kubernetes Cluster Autoscaler"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "autoscaling:UpdateAutoScalingGroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "batch:ListJobs",
          "batch:DescribeJobQueues",
          "batch:DescribeJobs",
          "policy:PodDisruptionBudgets",
          "storage.k8s.io:csidrivers",
          "storage.k8s.io:csinodes",
          "storage.k8s.io:csistoragecapacities",
          "storage.k8s.io:storageclasses",
          "sts:AssumeRole*",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}


data "external" "oidc_provider" {
  program = ["bash", "${path.module}/get_oidc_provider.sh", aws_eks_cluster.eks_gpu.name]

  # Optional: Pass AWS credentials if needed
  # environment = {
  #   AWS_ACCESS_KEY_ID     = var.aws_access_key_id
  #   AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
  #   AWS_DEFAULT_REGION    = var.aws_region
  # }

  depends_on = [aws_eks_cluster.eks_gpu]
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  url             = data.external.oidc_provider.result["oidc_url"]
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.external.oidc_provider.result["thumbprint"]]
}


output "oidc_provider_url" {
  value = data.external.oidc_provider.result["oidc_url"]
}

resource "aws_iam_role" "cluster_autoscaler" {
  name = "eks-cluster-autoscaler"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/https://${data.external.oidc_provider.result["oidc_url"]}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringLike" : {
            "$oidc_provider:aud" : "sts.amazonaws.com",
            "$oidc_provider:sub" : "system:serviceaccount:kube-system:*"
          }
        }
      }
    ]
  })
}



resource "aws_iam_role_policy_attachment" "cluster_autoscaler_attach" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}
