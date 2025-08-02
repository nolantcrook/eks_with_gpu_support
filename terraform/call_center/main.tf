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
  contact_flow_logs_enabled        = true
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

# Note: Contact trace records are not supported for all instance types
# This will be set up manually if needed

# Note: Contact flow logs are not supported via Terraform aws_connect_instance_storage_config
# They need to be enabled manually in the AWS Console or via AWS CLI
# We'll create the log group for when you enable it manually

################################################################################
# CloudWatch Log Group for Connect Logs
################################################################################

resource "aws_cloudwatch_log_group" "connect_logs" {
  name              = "/aws/connect/${aws_connect_instance.main.id}"
  retention_in_days = 7

  tags = var.tags
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

# resource "aws_lexv2models_bot" "rental_bot" {
#   name     = "${var.project_name}-rental-bot"
#   role_arn = aws_iam_role.lex_bot_role.arn

#   data_privacy {
#     child_directed = false
#   }

#   idle_session_ttl_in_seconds = 600

#   tags = merge(var.tags,{
#     AmazonConnectEnabled = "True"
#   })
# }

# resource "aws_lexv2models_bot_version" "rental_bot" {
#   bot_id = aws_lexv2models_bot.rental_bot.id

#   locale_specification = {
#     en_US = {
#       source_bot_version = "DRAFT"
#     }
#   }

# depends_on = [
#   null_resource.build_bot_locale
# ]
# }

# resource "aws_lexv2models_bot_locale" "en_us" {
#   bot_id      = aws_lexv2models_bot.rental_bot.id
#   bot_version = "DRAFT"
#   locale_id   = "en_US"

#   n_lu_intent_confidence_threshold = 0.40
#   voice_settings {
#     voice_id = "Joanna"
#   }

#   depends_on = [aws_lexv2models_bot.rental_bot]
# }

# Note: Using built-in AMAZON.AlphaNumeric slot type instead of custom slot type
# to avoid provider inconsistency issues with complex slot configurations

# Intent for handling rental queries
# resource "aws_lexv2models_intent" "rental_query_intent" {
#   bot_id      = aws_lexv2models_bot.rental_bot.id
#   bot_version = "DRAFT"
#   locale_id   = "en_US"
#   name        = "RentalQueryIntent"

#   description = "Intent for handling equipment rental queries"

#   # Sample utterances will include:
#   # "What equipment do you have"
#   # "How much does the cotton candy machine cost"
#   # "Is the cotton candy machine available on August 28th"
#   # These need to be configured manually in AWS Console

#   depends_on = [
#     aws_lexv2models_bot_locale.en_us
#   ]
# }


# Note: The Lex bot configuration will need to be completed manually in the AWS Console
# or using the AWS CLI after the initial Terraform deployment. This is due to provider
# limitations with complex Lex V2 configurations.

################################################################################
# Lambda Function for Bedrock Knowledge Base Integration
################################################################################

resource "aws_lambda_function" "rental_query" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-rental-query"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 60
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = "hauliday_reservations"
      MODEL_ID            = var.bedrock_model_id
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy.lambda_bedrock_access,
    aws_iam_role_policy.lambda_dynamodb_access,
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
    content  = file("${path.module}/lambda_function.py")
    filename = "lambda_function.py"
  }
}

# Lambda permission for Lex to invoke the function
resource "aws_lambda_permission" "allow_lex" {
  statement_id  = "AllowExecutionFromLex"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rental_query.function_name
  principal     = "lexv2.amazonaws.com"
  source_arn    = "arn:aws:lex:${var.aws_region}:${data.aws_caller_identity.current.account_id}:bot-alias/*"
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


################################################################################
# Connect Queue
################################################################################

resource "aws_connect_queue" "rental_queue" {
  instance_id           = aws_connect_instance.main.id
  name                  = "RentalQueue"
  description           = "Queue for equipment rental queries"
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

# # Configure Lex bot alias with Lambda code hook using a null_resource
# # This is necessary because Terraform AWS provider doesn't support Lambda code hooks for Lex V2 aliases
# resource "null_resource" "configure_lex_alias_with_lambda" {
#   depends_on = [
#     aws_lexv2models_bot.rental_bot,
#     aws_lexv2models_bot_version.rental_bot,
#     aws_lambda_function.rental_query,
#     aws_lambda_permission.allow_lex
#   ]

#   provisioner "local-exec" {
#     command = <<-EOT
#       LEX_BOT_ID=${aws_lexv2models_bot.rental_bot.id} \
#       LEX_ALIAS_NAME=TestBotAlias \
#       LAMBDA_ARN=${aws_lambda_function.rental_query.arn} \
#       ~/venv/bin/python ${path.module}/create_lex_alias_with_lambda.py
#     EOT
#   }

#   # Trigger on changes to the Lambda function or bot
#   triggers = {
#     lambda_arn        = aws_lambda_function.rental_query.arn
#     bot_id            = aws_lexv2models_bot.rental_bot.id
#     lambda_permission = aws_lambda_permission.allow_lex.id
#   }
# }

################################################################################
# Build Bot Locale with Sample Utterances
################################################################################

# # Add sample utterances and build the bot locale
# resource "null_resource" "build_bot_locale" {
#   depends_on = [
#     aws_lexv2models_intent.rental_query_intent,
#     aws_lexv2models_bot_locale.en_us
#   ]

#   provisioner "local-exec" {
#     command = <<-EOT
#       # Wait for bot to be ready (not in versioning state)
#       echo "Waiting for bot to be ready..."
#       while true; do
#         BOT_STATUS=$(aws lexv2-models describe-bot \
#           --bot-id ${aws_lexv2models_bot.rental_bot.id} \
#           --query 'botStatus' \
#           --output text)

#         if [ "$BOT_STATUS" = "Available" ]; then
#           echo "✅ Bot is ready!"
#           break
#         elif [ "$BOT_STATUS" = "Failed" ]; then
#           echo "❌ Bot failed!"
#           exit 1
#         else
#           echo "⏳ Bot status: $BOT_STATUS"
#           sleep 5
#         fi
#       done

#       # Add sample utterances to the intent
#       aws lexv2-models update-intent \
#         --bot-id ${aws_lexv2models_bot.rental_bot.id} \
#         --bot-version DRAFT \
#         --locale-id en_US \
#         --intent-id ${aws_lexv2models_intent.rental_query_intent.intent_id} \
#         --intent-name RentalQueryIntent \
#         --sample-utterances '[
#           {"utterance": "What equipment do you have"},
#           {"utterance": "What can I rent"},
#           {"utterance": "Show me your rental equipment"},
#           {"utterance": "How much does the cotton candy machine cost"},
#           {"utterance": "Is the cotton candy machine available"},
#           {"utterance": "Can I rent the cargo carrier"},
#           {"utterance": "What are your prices"},
#           {"utterance": "I need to rent something"},
#           {"utterance": "Tell me about your equipment"},
#           {"utterance": "I want to make a reservation"},
#           {"utterance": "Is it available"},
#           {"utterance": "How much does it cost"},
#           {"utterance": "Can I book it"}
#         ]'

#       # Wait a moment for the intent update to process
#       sleep 3

#       # Build the bot locale
#       echo "Building bot locale..."
#       aws lexv2-models build-bot-locale \
#         --bot-id ${aws_lexv2models_bot.rental_bot.id} \
#         --bot-version DRAFT \
#         --locale-id en_US

#       # Wait for build to complete
#       echo "Waiting for bot locale to build..."
#       RETRY_COUNT=0
#       MAX_RETRIES=60
#       while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
#         STATUS=$(aws lexv2-models describe-bot-locale \
#           --bot-id ${aws_lexv2models_bot.rental_bot.id} \
#           --bot-version DRAFT \
#           --locale-id en_US \
#           --query 'botLocaleStatus' \
#           --output text)

#         if [ "$STATUS" = "Built" ]; then
#           echo "✅ Bot locale built successfully!"
#           break
#         elif [ "$STATUS" = "Failed" ]; then
#           echo "❌ Bot locale build failed!"
#           exit 1
#         else
#           echo "⏳ Bot locale status: $STATUS (attempt $((RETRY_COUNT+1))/$MAX_RETRIES)"
#           sleep 10
#           RETRY_COUNT=$((RETRY_COUNT+1))
#         fi
#       done

#       if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
#         echo "❌ Bot locale build timed out after $MAX_RETRIES attempts"
#         exit 1
#       fi
#     EOT
#   }

#   # Trigger on changes to the bot or intents
#   triggers = {
#     bot_id    = aws_lexv2models_bot.rental_bot.id
#     intent_id = aws_lexv2models_intent.rental_query_intent.intent_id
#     locale_id = aws_lexv2models_bot_locale.en_us.id
#   }
# }

################################################################################
# Lex Bot Association with Amazon Connect
################################################################################

# # Associate Lex bot with Amazon Connect instance using a shell script
# resource "null_resource" "associate_lex_with_connect" {
#   depends_on = [
#     aws_connect_instance.main,
#     aws_lexv2models_bot.rental_bot,
#     null_resource.configure_lex_alias_with_lambda,
#     null_resource.build_bot_locale
#   ]

#   provisioner "local-exec" {
#     command = <<-EOT
#       CONNECT_INSTANCE_ID=${aws_connect_instance.main.id} \
#       LEX_BOT_ID=${aws_lexv2models_bot.rental_bot.id} \
#       LEX_BOT_ALIAS_ID=TSTALIASID \
#       ${path.module}/associate_lex_with_connect.sh
#     EOT
#   }

#   # Trigger on changes to the Connect instance or Lex bot
#   triggers = {
#     connect_instance_id  = aws_connect_instance.main.id
#     lex_bot_id           = aws_lexv2models_bot.rental_bot.id
#     lex_alias_configured = null_resource.configure_lex_alias_with_lambda.id
#     bot_built            = null_resource.build_bot_locale.id
#   }
# }
