# Current Working Lex Bot Configuration

## Overview
The Amazon Connect call center is now working with Lex V2 bot integration and Bedrock Knowledge Base queries.

## Current Configuration

### Lex Bot Details
- **Bot Name**: `call-center-knowledge-base-bot`
- **Bot ID**: `QEPIRCXWA6`
- **Status**: Available
- **Role ARN**: `arn:aws:iam::891377073036:role/call-center-lex-bot-role`

### Bot Alias
- **Alias Name**: `TestBotAlias`
- **Alias ID**: `TSTALIASID`
- **Status**: Available
- **Lambda Code Hook**: ✅ Configured
  - **Lambda ARN**: `arn:aws:lambda:us-west-2:891377073036:function:call-center-knowledge-base-query`

### Intents

#### 1. KnowledgeQueryIntent
- **Intent ID**: `O9SRK4MLN0`
- **Sample Utterance**: "I want you to describe this knowledgebase"
- **Slots**: None defined
- **Code Hook**: None (handled at alias level)

#### 2. FallbackIntent
- **Intent ID**: `FALLBCKINT`
- **Purpose**: Handles unrecognized inputs
- **Sample Utterances**: None
- **Slots**: None defined

### Lambda Function
- **Function Name**: `call-center-knowledge-base-query`
- **Runtime**: `python3.11`
- **Handler**: `lambda_function.lambda_handler`
- **Timeout**: 30 seconds
- **Environment Variables**:
  - `MODEL_ID`: `anthropic.claude-3-sonnet-20240229-v1:0`
  - `KNOWLEDGE_BASE_ID`: `GBKMWZQTAX`

### Key Working Features
1. **Lambda Code Hook**: Configured at the bot alias level (not intent level)
2. **No Slots Required**: The Lambda function extracts user input from `inputTranscript`
3. **Sample Utterance**: "I want you to describe this knowledgebase" triggers the intent
4. **Bedrock Integration**: Successfully queries the knowledge base and returns responses

## How It Works
1. User calls the Amazon Connect number
2. User says "I want you to describe this knowledgebase"
3. Lex recognizes the intent and invokes the Lambda function
4. Lambda extracts the user's input from the event transcript
5. Lambda queries the Bedrock Knowledge Base
6. Lambda returns the response to Lex
7. Lex speaks the response to the user

## Terraform Configuration
The current Terraform files reflect this working configuration:
- `main.tf`: Contains the basic Lex bot and intent configuration
- `iam.tf`: Contains all necessary IAM roles and policies
- Lambda permissions are correctly configured for Lex V2 bot alias

## Manual Configuration Required
Some aspects of Lex V2 configuration cannot be fully automated via Terraform:
- Sample utterances must be added manually in the AWS Console
- Lambda code hooks for aliases are configured via the `create_lex_alias_with_lambda.py` script

## Testing
To test the system:
1. Call the Amazon Connect phone number
2. Say "I want you to describe this knowledgebase"
3. The system should respond with information from the Bedrock Knowledge Base
