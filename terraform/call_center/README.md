# Amazon Connect Call Center with Lex & Lambda Rental System

This Terraform configuration deploys a complete Amazon Connect call center system integrated with Amazon Lex and AWS Lambda for handling equipment rental inquiries, similar to the Hauliday rental system but optimized for voice interactions.

## Architecture

```
Phone Call → Amazon Connect → Amazon Lex → AWS Lambda → DynamoDB (Hauliday Reservations)
                   ↓                ↓              ↓
              Voice to Text    Intent Recognition  Bedrock Claude AI
```

## Features

- **Voice-to-Text Processing**: Amazon Connect handles incoming calls and converts speech to text
- **Intent Recognition**: Amazon Lex identifies rental-related queries with high accuracy
- **AI-Powered Responses**: AWS Lambda uses Bedrock Claude 3 Sonnet for intelligent responses
- **Inventory Integration**: Real-time availability checking against existing Hauliday reservations
- **Conversation Memory**: Maintains context throughout the call session
- **Input Validation**: Guards against non-rental queries and prompt injection

## Equipment Catalog

- **Cotton Candy Machine**: $40/day - Professional machine with supplies for 50 servings
- **Cargo Carrier**: $30/day - Heavy-duty roof-top carrier for equipment transport

## Deployment

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform installed
- Python 3.x with boto3 (in virtual environment at `~/venv`)
- Existing `hauliday_reservations` DynamoDB table

### Deploy

```bash
# Deploy the infrastructure
terragrunt apply

# The system will automatically:
# 1. Create Connect instance, Lex bot, and Lambda function
# 2. Configure Lex bot with sample utterances and build the locale
# 3. Set up Lambda code hook integration
# 4. Associate Lex bot with Connect instance
```

### Test the System

```bash
# Run comprehensive tests
./test_system.py

# Manual association if needed
./associate_lex_with_connect.sh
```

## Manual Setup (After Deployment)

### 1. Create Contact Flow

1. Go to AWS Connect Console → Contact flows
2. Create a new contact flow
3. Add a "Get customer input" block
4. Configure it to use the Lex bot: `call-center-rental-bot`
5. Set up call routing to your phone number

### 2. Test Voice Interactions

Call your Connect number and try these queries:

- "What equipment do you have?"
- "How much does the cotton candy machine cost?"
- "Is the cotton candy machine available on August 28th?"
- "Can I rent the cargo carrier?"

## Sample Conversations

### Equipment Inquiry
```
Caller: "What equipment do you have available?"
Bot: "We have two types of rental equipment available:

Cotton Candy Machine - A professional cotton candy machine perfect for parties and events. It includes supplies for 50 servings and rents for $40 per day.

Cargo Carrier - A heavy-duty roof-top cargo carrier for transporting equipment or luggage. It rents for $30 per day."
```

### Availability Check
```
Caller: "Is the cotton candy machine available August 30th?"
Bot: "✅ Great news! The Cotton Candy Machine is available from 2025-08-30 to 2025-08-30. The daily rate is $40. Would you like to make a reservation?"
```

### Pricing Query
```
Caller: "How much does the cotton candy machine cost?"
Bot: "The Cotton Candy Machine rents for $40 per day. It's a professional cotton candy machine that's perfect for parties and events."
```

## Files Structure

```
terraform/call_center/
├── main.tf                           # Main Terraform configuration
├── variables.tf                      # Input variables
├── outputs.tf                        # Output values
├── iam.tf                           # IAM roles and policies
├── data.tf                          # Data sources
├── lambda_function.py               # Lambda function code
├── create_lex_alias_with_lambda.py  # Lex alias configuration script
├── associate_lex_with_connect.sh    # Connect-Lex association script
├── test_system.py                   # Comprehensive test suite
└── README.md                        # This file
```

## Testing

The `test_system.py` script provides comprehensive testing:

- **Lambda Function Tests**: Various rental queries and error scenarios
- **Lex Bot Tests**: Intent recognition accuracy
- **DynamoDB Integration**: Table access and availability checking
- **Connect Integration**: Lex-Connect association verification
- **End-to-End Flow**: Complete conversation simulation

### Run Tests

```bash
# Set environment variables (optional, will use defaults)
export LAMBDA_FUNCTION_NAME=call-center-rental-query
export LEX_BOT_ID=<your-bot-id>
export CONNECT_INSTANCE_ID=<your-connect-instance-id>

# Run all tests
./test_system.py
```

## Troubleshooting

### Common Issues

1. **Bot Locale Not Built**: Run the build script manually
   ```bash
   aws lexv2-models build-bot-locale --bot-id <BOT_ID> --bot-version DRAFT --locale-id en_US
   ```

2. **Connect-Lex Not Associated**: Run the association script
   ```bash
   ./associate_lex_with_connect.sh <CONNECT_INSTANCE_ID> <LEX_BOT_ID> <LEX_BOT_ALIAS_ID>
   ```

3. **Lambda Timeout**: Check CloudWatch logs for errors
   ```bash
   aws logs tail /aws/lambda/call-center-rental-query --follow
   ```

### Debug Commands

```bash
# Check bot status
aws lexv2-models describe-bot --bot-id <BOT_ID>

# Check bot locale build status
aws lexv2-models describe-bot-locale --bot-id <BOT_ID> --bot-version DRAFT --locale-id en_US

# Test Lex directly
aws lexv2-runtime recognize-text --bot-id <BOT_ID> --bot-alias-id TSTALIASID --locale-id en_US --session-id test --text "What equipment do you have?"

# Test Lambda directly
aws lambda invoke --function-name call-center-rental-query --payload '{"inputTranscript":"What equipment do you have?","sessionState":{"intent":{"name":"RentalQueryIntent","slots":{}},"sessionAttributes":{}}}' response.json
```

## Security

- **Input Validation**: Filters non-rental queries and prompt injection attempts
- **IAM Least Privilege**: Each service has minimal required permissions
- **Encryption**: Data encrypted in transit and at rest
- **Call Recording**: Optional call recording to S3 with encryption

## Cost Optimization

- **Pay-per-use**: Lambda, Lex, and DynamoDB charge only for actual usage
- **No idle costs**: No servers running when not in use
- **Efficient AI**: Uses Claude 3 Sonnet for optimal cost/performance balance

## Integration with Hauliday

This system integrates seamlessly with the existing Hauliday rental platform:

- **Shared Database**: Uses the same `hauliday_reservations` DynamoDB table
- **Same Equipment**: Cotton candy machine and cargo carrier from Hauliday catalog
- **Consistent Pricing**: $40/day and $30/day matching web prices
- **Real-time Availability**: Checks actual reservations before confirming availability

## Support

For issues or questions:
1. Check CloudWatch logs for detailed error information
2. Run `./test_system.py` to diagnose system health
3. Review AWS service quotas and limits
4. Verify all IAM permissions are correctly configured
