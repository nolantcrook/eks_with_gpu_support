# Data Sources
################################################################################

# the knowledge base id is stored in the terraform state of the rag layer, this accessed in data.tf. Don't create a new secret data source


################################################################################

# Amazon Connect Call Center Infrastructure
# This module creates an Amazon Connect instance with Lex integration for voice-based AI interactions
################################################################################
# Amazon Connect Instance
################################################################################

resource "aws_connect_instance" "main" {
  identity_management_type         = "CONNECT_MANAGED"
  inbound_calls_enabled            = true
  outbound_calls_enabled           = false
  instance_alias                   = var.connect_instance_alias
  auto_resolve_best_voices_enabled = true
  tags                             = var.tags
}

# Note: Contact trace records storage may not be supported in all regions
# Removing this configuration as it's causing deployment issues

# Enable call recordings
resource "aws_connect_instance_storage_config" "call_recordings" {
  instance_id   = aws_connect_instance.main.id
  resource_type = "CALL_RECORDINGS"

  storage_config {
    s3_config {
      bucket_name   = aws_s3_bucket.connect_logs.bucket
      bucket_prefix = "call-recordings"
    }
    storage_type = "S3"
  }
}

################################################################################
# S3 Bucket for Connect Logs and Recordings
################################################################################

resource "aws_s3_bucket" "connect_logs" {
  bucket = "${var.project_name}-connect-logs-${random_string.bucket_suffix.result}"

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "connect_logs" {
  bucket = aws_s3_bucket.connect_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "connect_logs" {
  bucket = aws_s3_bucket.connect_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "connect_logs" {
  bucket = aws_s3_bucket.connect_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

################################################################################
# Amazon Lex Bot for Voice Interactions
################################################################################

resource "aws_lexv2models_bot" "knowledge_base_bot" {
  name     = "${var.project_name}-knowledge-base-bot"
  role_arn = aws_iam_role.lex_bot_role.arn

  data_privacy {
    child_directed = false
  }

  idle_session_ttl_in_seconds = 300

  tags = var.tags
}

resource "aws_lexv2models_bot_version" "knowledge_base_bot" {
  bot_id = aws_lexv2models_bot.knowledge_base_bot.id

  locale_specification = {
    en_US = {
      source_bot_version = "DRAFT"
    }
  }

  depends_on = [
    aws_lexv2models_intent.knowledge_query_intent
  ]
}

resource "aws_lexv2models_bot_locale" "en_us" {
  bot_id      = aws_lexv2models_bot.knowledge_base_bot.id
  bot_version = "DRAFT"
  locale_id   = "en_US"

  n_lu_intent_confidence_threshold = 0.40
  voice_settings {
    voice_id = "Joanna"
  }

  depends_on = [aws_lexv2models_bot.knowledge_base_bot]
}

# Note: Using built-in AMAZON.AlphaNumeric slot type instead of custom slot type
# to avoid provider inconsistency issues with complex slot configurations

# Intent for handling knowledge base queries
resource "aws_lexv2models_intent" "knowledge_query_intent" {
  bot_id      = aws_lexv2models_bot.knowledge_base_bot.id
  bot_version = "DRAFT"
  locale_id   = "en_US"
  name        = "KnowledgeQueryIntent"

  description = "Intent for querying the knowledge base"

  # Sample utterances for the intent
  # Note: These are configured manually in the AWS Console for Lex V2
  # The current working utterance is: "I want you to describe this knowledgebase"

  # No slots defined - the Lambda function handles the query processing
  # without requiring specific slot extraction

  depends_on = [
    aws_lexv2models_bot_locale.en_us
  ]
}


# Note: The Lex bot configuration will need to be completed manually in the AWS Console
# or using the AWS CLI after the initial Terraform deployment. This is due to provider
# limitations with complex Lex V2 configurations.

################################################################################
# Lambda Function for Bedrock Knowledge Base Integration
################################################################################

resource "aws_lambda_function" "knowledge_base_query" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-knowledge-base-query"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      KNOWLEDGE_BASE_ID = local.knowledge_base_id
      MODEL_ID          = var.bedrock_model_id
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy.lambda_bedrock_access,
    # aws_cloudwatch_log_group.lambda_logs
  ]
}

# # CloudWatch Log Group for Lambda
# resource "aws_cloudwatch_log_group" "lambda_logs" {
#   name              = "/aws/lambda/${var.project_name}-knowledge-base-query"
#   retention_in_days = 14

#   tags = var.tags
# }

# Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"
  source {
    content = templatefile("${path.module}/lambda_function.py", {
      knowledge_base_id = local.knowledge_base_id
      model_id          = var.bedrock_model_id
    })
    filename = "lambda_function.py"
  }
}

# Lambda permission for Lex to invoke the function
resource "aws_lambda_permission" "allow_lex" {
  statement_id  = "AllowExecutionFromLex"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.knowledge_base_query.function_name
  principal     = "lexv2.amazonaws.com"
  source_arn    = "arn:aws:lex:us-west-2:891377073036:bot-alias/QEPIRCXWA6/TSTALIASID"
}


################################################################################
# Phone Number (if available)
################################################################################

resource "aws_connect_phone_number" "main" {
  count        = var.claim_phone_number ? 1 : 0
  target_arn   = aws_connect_instance.main.arn
  country_code = var.phone_number_country_code
  type         = "TOLL_FREE"
  description  = "Main phone number for knowledge base queries"

  tags = var.tags
}

################################################################################
# Connect Queue
################################################################################

resource "aws_connect_queue" "knowledge_base_queue" {
  instance_id           = aws_connect_instance.main.id
  name                  = "KnowledgeBaseQueue"
  description           = "Queue for knowledge base queries"
  hours_of_operation_id = aws_connect_hours_of_operation.main.hours_of_operation_id

  tags = var.tags
}

resource "aws_connect_hours_of_operation" "main" {
  instance_id = aws_connect_instance.main.id
  name        = "24x7"
  description = "24 hours a day, 7 days a week"
  time_zone   = "UTC"

  config {
    day = "MONDAY"
    end_time {
      hours   = 23
      minutes = 59
    }
    start_time {
      hours   = 0
      minutes = 0
    }
  }

  config {
    day = "TUESDAY"
    end_time {
      hours   = 23
      minutes = 59
    }
    start_time {
      hours   = 0
      minutes = 0
    }
  }

  config {
    day = "WEDNESDAY"
    end_time {
      hours   = 23
      minutes = 59
    }
    start_time {
      hours   = 0
      minutes = 0
    }
  }

  config {
    day = "THURSDAY"
    end_time {
      hours   = 23
      minutes = 59
    }
    start_time {
      hours   = 0
      minutes = 0
    }
  }

  config {
    day = "FRIDAY"
    end_time {
      hours   = 23
      minutes = 59
    }
    start_time {
      hours   = 0
      minutes = 0
    }
  }

  config {
    day = "SATURDAY"
    end_time {
      hours   = 23
      minutes = 59
    }
    start_time {
      hours   = 0
      minutes = 0
    }
  }

  config {
    day = "SUNDAY"
    end_time {
      hours   = 23
      minutes = 59
    }
    start_time {
      hours   = 0
      minutes = 0
    }
  }

  tags = var.tags
}

################################################################################
# Manual Setup Instructions
################################################################################

# Note: The Lex bot association with Connect needs to be done manually or via a separate script
# This is due to timing issues with AWS provider consistency and bot readiness detection
#
# To associate the bot manually:
# 1. Go to AWS Connect Console -> Contact flows -> Amazon Lex
# 2. Add the bot: call-center-knowledge-base-bot
# 3. Region: us-west-2
#
# Or use AWS CLI:
# aws connect associate-lex-bot \
#   --instance-id ${aws_connect_instance.main.id} \
#   --lex-bot "Name=call-center-knowledge-base-bot,LexRegion=us-west-2" \
#   --region us-west-2

################################################################################
# Lex Bot Alias Configuration with Lambda Code Hook
################################################################################

# Configure Lex bot alias with Lambda code hook using a null_resource
# This is necessary because Terraform AWS provider doesn't support Lambda code hooks for Lex V2 aliases
resource "null_resource" "configure_lex_alias_with_lambda" {
  depends_on = [
    aws_lexv2models_bot.knowledge_base_bot,
    aws_lexv2models_bot_version.knowledge_base_bot,
    aws_lambda_function.knowledge_base_query,
    aws_lambda_permission.allow_lex
  ]

  provisioner "local-exec" {
    command = <<-EOT
      LEX_BOT_ID=${aws_lexv2models_bot.knowledge_base_bot.id} \
      LEX_ALIAS_NAME=TestBotAlias \
      LAMBDA_ARN=${aws_lambda_function.knowledge_base_query.arn} \
      python3 ${path.module}/create_lex_alias_with_lambda.py
    EOT
  }

  # Trigger on changes to the Lambda function or bot
  triggers = {
    lambda_arn        = aws_lambda_function.knowledge_base_query.arn
    bot_id            = aws_lexv2models_bot.knowledge_base_bot.id
    lambda_permission = aws_lambda_permission.allow_lex.id
  }
}

################################################################################
# Lex Bot Association with Amazon Connect
################################################################################

# Associate Lex bot with Amazon Connect instance using a null_resource
# This automates the manual association step
# resource "null_resource" "associate_lex_with_connect" {
#   depends_on = [
#     aws_connect_instance.main,
#     aws_lexv2models_bot.knowledge_base_bot,
#     null_resource.configure_lex_alias_with_lambda
#   ]

#   provisioner "local-exec" {
#     command = <<-EOT
#       CONNECT_INSTANCE_ID=${aws_connect_instance.main.id} \
#       LEX_BOT_NAME=${aws_lexv2models_bot.knowledge_base_bot.name} \
#       LEX_REGION=${var.aws_region} \
#       python3 ${path.module}/associate_lex_with_connect.py
#     EOT
#   }

#   # Trigger on changes to the Connect instance or Lex bot
#   triggers = {
#     connect_instance_id = aws_connect_instance.main.id
#     lex_bot_name = aws_lexv2models_bot.knowledge_base_bot.name
#     lex_alias_configured = null_resource.configure_lex_alias_with_lambda.id
#   }
# }
