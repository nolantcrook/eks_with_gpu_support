resource "aws_iam_policy" "umami_policy" {
  name        = "UmamiPolicy"
  description = "IAM policy for Umami API to access SQS and DynamoDB"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:us-west-2:891377073036:secret:umami/*" # Replace with your SQS queue ARN
      }
    ]
  })
}

resource "aws_iam_role" "umami_role" {
  name = "umami-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringLike" : {
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub" : "system:serviceaccount:umami:umami-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "umami_policy_attach" {
  role       = aws_iam_role.umami_role.name
  policy_arn = aws_iam_policy.umami_policy.arn
}
