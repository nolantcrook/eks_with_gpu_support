resource "aws_iam_policy" "tolby_policy" {
  name        = "tolbyPolicy"
  description = "IAM policy for tolby send emails"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail",
          "ses:SendTemplatedEmail",
          "ses:GetSendStatistics"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "tolby_role" {
  name = "eks-tolby-role"

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
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub" : "system:serviceaccount:tolby:tolby-backend-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "tolby_policy_attach" {
  role       = aws_iam_role.tolby_role.name
  policy_arn = aws_iam_policy.tolby_policy.arn
}
