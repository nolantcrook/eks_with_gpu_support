resource "aws_iam_policy" "flask_api_policy" {
  name        = "FlaskApiPolicy"
  description = "IAM policy for Flask API to access SQS and DynamoDB"
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
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = [
          "arn:aws:dynamodb:us-west-2:891377073036:table/generate_image_status", # Replace with your DynamoDB table ARN
          "arn:aws:dynamodb:us-west-2:891377073036:table/invokeai_auth_codes"    # Replace with your DynamoDB table ARN
        ]
      }
    ]
  })
}

resource "aws_iam_role" "flask_api_role" {
  name = "eks-flask-api-role"

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
            "${aws_iam_openid_connect_provider.eks_oidc.url}:sub" : "system:serviceaccount:invokeai-api:invokeai-api-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "flask_api_policy_attach" {
  role       = aws_iam_role.flask_api_role.name
  policy_arn = aws_iam_policy.flask_api_policy.arn
}
