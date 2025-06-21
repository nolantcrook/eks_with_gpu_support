output "connect_instance_id" {
  description = "ID of the Amazon Connect instance"
  value       = aws_connect_instance.main.id
}

output "connect_instance_arn" {
  description = "ARN of the Amazon Connect instance"
  value       = aws_connect_instance.main.arn
}

output "connect_instance_alias" {
  description = "Alias of the Amazon Connect instance"
  value       = aws_connect_instance.main.instance_alias
}

output "lex_bot_id" {
  description = "ID of the Lex bot"
  value       = aws_lexv2models_bot.knowledge_base_bot.id
}

output "lex_bot_arn" {
  description = "ARN of the Lex bot"
  value       = aws_lexv2models_bot.knowledge_base_bot.arn
}

output "lex_bot_name" {
  description = "Name of the Lex bot"
  value       = aws_lexv2models_bot.knowledge_base_bot.name
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.knowledge_base_query.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.knowledge_base_query.arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for Connect logs"
  value       = aws_s3_bucket.connect_logs.bucket
}

output "phone_number" {
  description = "Phone number claimed for the Connect instance (if enabled)"
  value       = var.claim_phone_number ? aws_connect_phone_number.main[0].phone_number : null
}

output "knowledge_base_id" {
  description = "ID of the Bedrock knowledge base being used"
  value       = local.knowledge_base_id
}

output "lex_bot_manual_setup_required" {
  description = "Setup status for Lex bot integration"
  value       = <<-EOT
    ✅ Lex bot integration is now automated!

    Completed automatically:
    ✓ Lex bot alias configured with Lambda code hook
    ✓ Lex bot associated with Amazon Connect

    Next steps:
    1. Create a contact flow in the AWS Console or uncomment the contact flow resource in main.tf
    2. Associate the contact flow with a phone number or queue
    3. Test the complete voice interaction flow

    Resources available:
    - Connect Instance: ${aws_connect_instance.main.instance_alias}
    - Lex Bot: ${aws_lexv2models_bot.knowledge_base_bot.name}
    - Lambda Function: ${aws_lambda_function.knowledge_base_query.function_name}
  EOT
}

output "setup_instructions" {
  description = "Instructions for using the deployed system"
  value       = <<-EOT
    Amazon Connect Call Center Infrastructure Deployed!

    ✅ Completed automatically:
    ✓ Connect instance created
    ✓ Lex bot created and configured
    ✓ Lambda function deployed for Bedrock integration
    ✓ S3 bucket configured for call recordings
    ✓ Lex bot alias configured with Lambda code hook
    ✓ Lex bot associated with Amazon Connect

    NEXT STEPS:

    1. Create Contact Flow (choose one method):
       Method A - AWS Console:
       - Go to AWS Connect Console -> Contact flows
       - Create a new contact flow
       - Add a "Get customer input" block
       - Configure it to use your Lex bot: ${aws_lexv2models_bot.knowledge_base_bot.name}

       Method B - Terraform:
       - Uncomment the contact flow resource in main.tf
       - Run terraform apply again

    2. Configure Contact Flow Routing:
       - Associate the contact flow with a phone number or queue

    3. Test the Setup:
       - Call the Connect instance
       - Ask questions about your knowledge base
       - The system will use Lex to capture your query and Lambda to query Bedrock

    Resources Created:
    - Connect Instance: ${aws_connect_instance.main.instance_alias}
    - Lex Bot: ${aws_lexv2models_bot.knowledge_base_bot.name}
    - Lambda Function: ${aws_lambda_function.knowledge_base_query.function_name}
    - S3 Bucket: ${aws_s3_bucket.connect_logs.bucket}
  EOT
}
