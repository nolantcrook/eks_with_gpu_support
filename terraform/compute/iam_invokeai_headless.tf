resource "aws_iam_policy" "invokeai_headless_policy" {
  name        = "InvokeAIHeadlessPolicy"
  description = "IAM policy for InvokeAI headless to access SQS, DynamoDB, and S3"
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
        Resource = "arn:aws:sqs:us-west-2:891377073036:*" # Replace with your SQS queue ARN
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          "arn:aws:dynamodb:us-west-2:891377073036:table/generate_image_status" # Replace with your DynamoDB table ARN
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::eks-invokeai-891377073036/*" # Replace with your S3 bucket ARN
      }
    ]
  })
}

resource "aws_iam_role" "invokeai_headless_role" {
  name = "eks-invokeai-headless-role"

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
            "${aws_iam_openid_connect_provider.eks_oidc.url}:sub" : "system:serviceaccount:invokeai-headless:invokeai-headless-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "invokeai_headless_policy_attach" {
  role       = aws_iam_role.invokeai_headless_role.name
  policy_arn = aws_iam_policy.invokeai_headless_policy.arn
}
