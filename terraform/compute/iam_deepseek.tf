resource "aws_iam_policy" "deepseek_headless_policy" {
  name        = "deepseekHeadlessPolicy"
  description = "IAM policy for deepseek headless to access SQS, DynamoDB, and S3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "arn:aws:sqs:us-west-2:${data.aws_caller_identity.current.account_id}:*" # Replace with your SQS queue ARN
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          "arn:aws:dynamodb:us-west-2:${data.aws_caller_identity.current.account_id}:table/generate_image_status" # Replace with your DynamoDB table ARN
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ],
        Resource = "arn:aws:ssm:us-west-2:${data.aws_caller_identity.current.account_id}:parameter/eks/efs-id"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        "Resource" : "arn:aws:secretsmanager:us-west-2:${data.aws_caller_identity.current.account_id}:secret:huggingface/token*"
      }
    ]
  })
}

resource "aws_iam_role" "deepseek_headless_role" {
  name = "eks-deepseek-headless-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${aws_iam_openid_connect_provider.eks_oidc.url}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringLike" : {
            "${aws_iam_openid_connect_provider.eks_oidc.url}:sub" : "system:serviceaccount:deepseek:deepseek-api-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "deepseek_headless_policy_attach" {
  role       = aws_iam_role.deepseek_headless_role.name
  policy_arn = aws_iam_policy.deepseek_headless_policy.arn
}
