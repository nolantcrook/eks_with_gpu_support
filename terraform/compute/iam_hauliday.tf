resource "aws_iam_policy" "hauliday_policy" {
  name        = "HaulidayPolicy"
  description = "IAM policy for Hauliday API to access SQS and DynamoDB"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "arn:aws:sqs:us-west-2:891377073036:*" # Replace with your SQS queue ARN
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.hauliday_notifications.arn
      },
      {
        Effect = "Allow"
        Action = [
          "Bedrock:InvokeModel"
        ]
        Resource = [
          "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = [                                                # Replace with your DynamoDB table ARN
          "arn:aws:dynamodb:us-west-2:891377073036:table/hauliday*" # Replace with your DynamoDB table ARN
        ]
      }
    ]
  })
}

resource "aws_iam_role" "hauliday_role" {
  name = "eks-hauliday-role"

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
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub" : "system:serviceaccount:hauliday:hauliday-backend-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "hauliday_policy_attach" {
  role       = aws_iam_role.hauliday_role.name
  policy_arn = aws_iam_policy.hauliday_policy.arn
}
