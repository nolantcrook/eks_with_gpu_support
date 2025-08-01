#!/bin/bash

# Associate Lex Bot with Amazon Connect
# This script handles the Lex-Connect integration that can't be done directly in Terraform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔗 Associating Lex Bot with Amazon Connect...${NC}"

# Get parameters from environment variables or command line
CONNECT_INSTANCE_ID=${CONNECT_INSTANCE_ID:-$1}
LEX_BOT_ID=${LEX_BOT_ID:-$2}
LEX_BOT_ALIAS_ID=${LEX_BOT_ALIAS_ID:-$3}

if [ -z "$CONNECT_INSTANCE_ID" ] || [ -z "$LEX_BOT_ID" ] || [ -z "$LEX_BOT_ALIAS_ID" ]; then
    echo -e "${RED}❌ Error: Missing required parameters${NC}"
    echo "Usage: $0 <CONNECT_INSTANCE_ID> <LEX_BOT_ID> <LEX_BOT_ALIAS_ID>"
    echo "Or set environment variables: CONNECT_INSTANCE_ID, LEX_BOT_ID, LEX_BOT_ALIAS_ID"
    exit 1
fi

echo -e "   Connect Instance: ${YELLOW}$CONNECT_INSTANCE_ID${NC}"
echo -e "   Lex Bot ID: ${YELLOW}$LEX_BOT_ID${NC}"
echo -e "   Lex Bot Alias: ${YELLOW}$LEX_BOT_ALIAS_ID${NC}"
echo

# Check if bot is already associated
echo -e "${BLUE}🔍 Checking existing associations...${NC}"
EXISTING_BOTS=$(aws connect list-bots \
  --instance-id "$CONNECT_INSTANCE_ID" \
  --lex-version V2 \
  --query "LexBots[?BotId=='$LEX_BOT_ID'].BotId" \
  --output text)

if [ "$EXISTING_BOTS" = "$LEX_BOT_ID" ]; then
    echo -e "${GREEN}✅ Bot is already associated with Connect instance${NC}"
    exit 0
fi

# Get AWS account ID and region for ARN construction
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "us-west-2")

# Construct the bot alias ARN
LEX_ALIAS_ARN="arn:aws:lex:${AWS_REGION}:${AWS_ACCOUNT_ID}:bot-alias/${LEX_BOT_ID}/${LEX_BOT_ALIAS_ID}"

# Associate the bot using associate-bot for Lex V2
echo -e "${BLUE}🔗 Associating Lex V2 bot with Connect instance...${NC}"
echo -e "   Using ARN: ${YELLOW}$LEX_ALIAS_ARN${NC}"
aws connect associate-bot \
  --instance-id "$CONNECT_INSTANCE_ID" \
  --lex-v2-bot AliasArn="$LEX_ALIAS_ARN"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Successfully associated Lex bot with Connect instance!${NC}"

    # Verify the association (with retry for eventual consistency)
    echo -e "${BLUE}🔍 Verifying association...${NC}"

    for i in {1..5}; do
        sleep 2
        VERIFICATION=$(aws connect list-bots \
          --instance-id "$CONNECT_INSTANCE_ID" \
          --lex-version V2 \
          --query "LexBots[?BotId=='$LEX_BOT_ID'].BotId" \
          --output text 2>/dev/null)

        if [ "$VERIFICATION" = "$LEX_BOT_ID" ]; then
            echo -e "${GREEN}✅ Association verified successfully!${NC}"
            echo
            echo -e "${YELLOW}📋 Next Steps:${NC}"
            echo "1. Create a Contact Flow in the AWS Connect Console"
            echo "2. Add a 'Get customer input' block and configure it to use your Lex bot"
            echo "3. Associate the contact flow with a phone number"
            echo "4. Test by calling the number"
            echo
            echo -e "${GREEN}🧪 Test the system: ./test_system.py${NC}"
            exit 0
        else
            echo -e "${YELLOW}⏳ Waiting for association to propagate (attempt $i/5)...${NC}"
        fi
    done

    echo -e "${YELLOW}⚠️  Association may still be propagating. Check manually:${NC}"
    echo "aws connect list-bots --instance-id $CONNECT_INSTANCE_ID --lex-version V2"
else
    echo -e "${RED}❌ Failed to associate bot with Connect instance${NC}"
    exit 1
fi
