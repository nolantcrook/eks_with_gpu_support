################################################################################
# IAM Role for Lex Bot
################################################################################

resource "aws_iam_role" "lex_bot_role" {
  name = "${var.project_name}-lex-bot-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lexv2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "lex_bot_policy" {
  name = "${var.project_name}-lex-bot-policy"
  role = aws_iam_role.lex_bot_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "polly:SynthesizeSpeech",
          "comprehend:DetectSentiment",
          "comprehend:DetectSyntax",
          "comprehend:DetectKeyPhrases",
          "comprehend:DetectEntities",
          "lexv2:DescribeBot",
          "lexv2:ListBotAliases"
        ]
        Resource = "*"
      }
    ]
  })
}

################################################################################
# IAM Role for Lambda Function
################################################################################

resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_bedrock_access" {
  name = "${var.project_name}-lambda-bedrock-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:RetrieveAndGenerate",
          "bedrock:Retrieve"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Note: aws_iam_role_policy creates an inline policy, not a managed policy
# So we don't need a separate policy attachment for inline policies

################################################################################
# IAM Role for Connect Service
################################################################################

resource "aws_iam_role" "connect_service_role" {
  name = "${var.project_name}-connect-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "connect.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "connect_s3_access" {
  name = "${var.project_name}-connect-s3-policy"
  role = aws_iam_role.connect_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.connect_logs.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.connect_logs.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "connect_lex_access" {
  name = "${var.project_name}-connect-lex-policy"
  role = aws_iam_role.connect_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lex:ListIntents",
          "lex:ListSlotTypes",
          "lex:ListSlots",
          "lex:ListBotAliases",
          "lex:DescribeBot",
          "lex:RecognizeText",
          "lex:RecognizeUtterance",
          "lex:StartConversation"
        ]
        Resource = "*"
      }
    ]
  })
}
