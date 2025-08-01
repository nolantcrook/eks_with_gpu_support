#!/usr/bin/env python3
"""
Comprehensive test suite for the Amazon Connect + Lex + Lambda rental system
"""

import json
import boto3
import sys
import os
from datetime import datetime
import traceback

# Colors for output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    PURPLE = '\033[0;35m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'  # No Color

def print_header(text):
    print(f"\n{Colors.BLUE}{'='*60}{Colors.NC}")
    print(f"{Colors.BLUE}{text}{Colors.NC}")
    print(f"{Colors.BLUE}{'='*60}{Colors.NC}")

def print_success(text):
    print(f"{Colors.GREEN}✅ {text}{Colors.NC}")

def print_error(text):
    print(f"{Colors.RED}❌ {text}{Colors.NC}")

def print_warning(text):
    print(f"{Colors.YELLOW}⚠️  {text}{Colors.NC}")

def print_info(text):
    print(f"{Colors.CYAN}ℹ️  {text}{Colors.NC}")

class RentalSystemTester:
    def __init__(self):
        self.lambda_client = boto3.client('lambda')
        self.lex_client = boto3.client('lexv2-runtime')
        self.connect_client = boto3.client('connect')
        self.dynamodb = boto3.resource('dynamodb')

        # Configuration (will be loaded from Terraform outputs)
        self.lambda_function_name = None
        self.lex_bot_id = None
        self.lex_bot_alias_id = None
        self.connect_instance_id = None
        self.dynamodb_table_name = None

        self.test_results = []

    def load_terraform_outputs(self):
        """Load configuration from terraform outputs"""
        try:
            # These would typically come from terraform output or environment variables
            self.lambda_function_name = os.environ.get('LAMBDA_FUNCTION_NAME', 'call-center-rental-query')
            self.lex_bot_id = os.environ.get('LEX_BOT_ID', 'D4IRHK9XHB')
            self.lex_bot_alias_id = os.environ.get('LEX_BOT_ALIAS_ID', 'TSTALIASID')
            self.connect_instance_id = os.environ.get('CONNECT_INSTANCE_ID', 'd855fff2-cb06-43ee-9af1-006878805bec')
            self.dynamodb_table_name = os.environ.get('DYNAMODB_TABLE_NAME', 'hauliday_reservations')

            print_info(f"Lambda Function: {self.lambda_function_name}")
            print_info(f"Lex Bot ID: {self.lex_bot_id}")
            print_info(f"Connect Instance: {self.connect_instance_id}")
            print_info(f"DynamoDB Table: {self.dynamodb_table_name}")

        except Exception as e:
            print_error(f"Failed to load configuration: {str(e)}")
            return False
        return True

    def test_lambda_function(self):
        """Test Lambda function with various scenarios"""
        print_header("Testing Lambda Function")

        test_cases = [
            {
                "name": "Equipment Catalog Query",
                "payload": {
                    "inputTranscript": "What equipment do you have available?",
                    "sessionState": {
                        "intent": {"name": "RentalQueryIntent", "slots": {}},
                        "sessionAttributes": {}
                    }
                },
                "expected_keywords": ["cotton candy", "cargo carrier", "$40", "$30"]
            },
            {
                "name": "Pricing Query",
                "payload": {
                    "inputTranscript": "How much does the cotton candy machine cost?",
                    "sessionState": {
                        "intent": {"name": "RentalQueryIntent", "slots": {}},
                        "sessionAttributes": {}
                    }
                },
                "expected_keywords": ["$40", "cotton candy"]
            },
            {
                "name": "Availability Check",
                "payload": {
                    "inputTranscript": "Is the cotton candy machine available August 30th?",
                    "sessionState": {
                        "intent": {"name": "RentalQueryIntent", "slots": {}},
                        "sessionAttributes": {}
                    }
                },
                "expected_keywords": ["cotton candy", "august", "available"]
            },
            {
                "name": "Invalid Query Handling",
                "payload": {
                    "inputTranscript": "Tell me about your company history",
                    "sessionState": {
                        "intent": {"name": "RentalQueryIntent", "slots": {}},
                        "sessionAttributes": {}
                    }
                },
                "expected_keywords": ["equipment rental", "help"]
            },
            {
                "name": "Error Handling - Malformed Event",
                "payload": {"malformed": "event"},
                "expected_keywords": ["didn't catch", "repeat"]
            }
        ]

        for test_case in test_cases:
            try:
                print(f"\n{Colors.PURPLE}🧪 Testing: {test_case['name']}{Colors.NC}")

                response = self.lambda_client.invoke(
                    FunctionName=self.lambda_function_name,
                    Payload=json.dumps(test_case['payload'])
                )

                result = json.loads(response['Payload'].read())

                if response['StatusCode'] == 200:
                    print_success(f"Lambda invocation successful")

                    # Check response structure
                    if 'messages' in result and len(result['messages']) > 0:
                        response_text = result['messages'][0]['content'].lower()
                        print_info(f"Response: {result['messages'][0]['content'][:100]}...")

                        # Check for expected keywords
                        keywords_found = [kw for kw in test_case['expected_keywords'] if kw.lower() in response_text]
                        if keywords_found:
                            print_success(f"Found expected keywords: {keywords_found}")
                            self.test_results.append(f"✅ Lambda Test - {test_case['name']}")
                        else:
                            print_warning(f"Expected keywords not found: {test_case['expected_keywords']}")
                            self.test_results.append(f"⚠️  Lambda Test - {test_case['name']} (partial)")
                    else:
                        print_error("No messages in response")
                        self.test_results.append(f"❌ Lambda Test - {test_case['name']}")
                else:
                    print_error(f"Lambda invocation failed with status {response['StatusCode']}")
                    self.test_results.append(f"❌ Lambda Test - {test_case['name']}")

            except Exception as e:
                print_error(f"Test failed: {str(e)}")
                self.test_results.append(f"❌ Lambda Test - {test_case['name']}")

    def test_lex_bot(self):
        """Test Lex bot intent recognition"""
        print_header("Testing Lex Bot")

        test_utterances = [
            "What equipment do you have?",
            "How much does the cotton candy machine cost?",
            "Is the cargo carrier available?",
            "I want to rent something",
            "Show me your prices"
        ]

        for utterance in test_utterances:
            try:
                print(f"\n{Colors.PURPLE}🧪 Testing utterance: '{utterance}'{Colors.NC}")

                response = self.lex_client.recognize_text(
                    botId=self.lex_bot_id,
                    botAliasId=self.lex_bot_alias_id,
                    localeId='en_US',
                    sessionId=f'test-session-{datetime.now().timestamp()}',
                    text=utterance
                )

                intent_name = response['sessionState']['intent']['name']
                confidence = response['interpretations'][0]['nluConfidence']['score']

                if intent_name == 'RentalQueryIntent' and confidence > 0.7:
                    print_success(f"Recognized as {intent_name} with confidence {confidence:.2f}")
                    self.test_results.append(f"✅ Lex Test - '{utterance[:30]}...'")
                else:
                    print_warning(f"Recognized as {intent_name} with confidence {confidence:.2f}")
                    self.test_results.append(f"⚠️  Lex Test - '{utterance[:30]}...'")

            except Exception as e:
                print_error(f"Lex test failed: {str(e)}")
                self.test_results.append(f"❌ Lex Test - '{utterance[:30]}...'")

    def test_dynamodb_integration(self):
        """Test DynamoDB table access"""
        print_header("Testing DynamoDB Integration")

        try:
            table = self.dynamodb.Table(self.dynamodb_table_name)

            # Test table scan
            response = table.scan(Limit=5)
            item_count = response['Count']

            print_success(f"Successfully connected to DynamoDB table")
            print_info(f"Found {item_count} reservation records")

            if item_count > 0:
                # Show sample reservation
                sample_item = response['Items'][0]
                print_info(f"Sample reservation: {sample_item.get('equipment_id', 'N/A')} for {sample_item.get('start_date', 'N/A')}")

            self.test_results.append("✅ DynamoDB Integration")

        except Exception as e:
            print_error(f"DynamoDB test failed: {str(e)}")
            self.test_results.append("❌ DynamoDB Integration")

    def test_connect_integration(self):
        """Test Amazon Connect integration"""
        print_header("Testing Amazon Connect Integration")

        try:
            # Check if Lex bot is associated with Connect
            response = self.connect_client.list_bots(
                InstanceId=self.connect_instance_id,
                LexVersion='V2'
            )

            # For Lex V2, we need to check the AliasArn
            associated_bot_arns = []
            for bot in response['LexBots']:
                if 'LexV2Bot' in bot and 'AliasArn' in bot['LexV2Bot']:
                    associated_bot_arns.append(bot['LexV2Bot']['AliasArn'])

            # Construct expected ARN
            expected_arn = f"arn:aws:lex:us-west-2:891377073036:bot-alias/{self.lex_bot_id}/{self.lex_bot_alias_id}"

            if expected_arn in associated_bot_arns:
                print_success("Lex bot is associated with Connect instance")
                print_info(f"Bot ARN: {expected_arn}")
                self.test_results.append("✅ Connect-Lex Association")
            else:
                print_warning("Lex bot is not associated with Connect instance")
                print_info("Run the association script: ./associate_lex_with_connect.sh")
                self.test_results.append("⚠️  Connect-Lex Association (needs setup)")

        except Exception as e:
            print_error(f"Connect integration test failed: {str(e)}")
            self.test_results.append("❌ Connect Integration")

    def test_end_to_end_flow(self):
        """Test complete end-to-end flow"""
        print_header("Testing End-to-End Flow")

        try:
            # Simulate a complete conversation flow
            session_id = f"e2e-test-{datetime.now().timestamp()}"

            # Step 1: Ask about equipment
            print(f"\n{Colors.PURPLE}🧪 Step 1: Equipment inquiry{Colors.NC}")
            lex_response = self.lex_client.recognize_text(
                botId=self.lex_bot_id,
                botAliasId=self.lex_bot_alias_id,
                localeId='en_US',
                sessionId=session_id,
                text="What equipment do you have?"
            )

            if lex_response['sessionState']['intent']['name'] == 'RentalQueryIntent':
                print_success("Lex correctly identified rental query intent")

                # Step 2: Test Lambda with pricing question
                print(f"\n{Colors.PURPLE}🧪 Step 2: Pricing inquiry{Colors.NC}")
                lambda_response = self.lambda_client.invoke(
                    FunctionName=self.lambda_function_name,
                    Payload=json.dumps({
                        "inputTranscript": "How much does the cotton candy machine cost?",
                        "sessionState": {
                            "intent": {"name": "RentalQueryIntent", "slots": {}},
                            "sessionAttributes": {}
                        }
                    })
                )

                result = json.loads(lambda_response['Payload'].read())
                if 'messages' in result and '$40' in result['messages'][0]['content']:
                    print_success("Lambda correctly provided pricing information")
                    self.test_results.append("✅ End-to-End Flow")
                else:
                    print_error("Lambda pricing response incorrect")
                    self.test_results.append("❌ End-to-End Flow")
            else:
                print_error("Lex failed to identify rental query intent")
                self.test_results.append("❌ End-to-End Flow")

        except Exception as e:
            print_error(f"End-to-end test failed: {str(e)}")
            self.test_results.append("❌ End-to-End Flow")

    def print_summary(self):
        """Print test summary"""
        print_header("Test Summary")

        passed = len([r for r in self.test_results if r.startswith('✅')])
        warnings = len([r for r in self.test_results if r.startswith('⚠️')])
        failed = len([r for r in self.test_results if r.startswith('❌')])
        total = len(self.test_results)

        print(f"\n{Colors.GREEN}Passed: {passed}{Colors.NC}")
        print(f"{Colors.YELLOW}Warnings: {warnings}{Colors.NC}")
        print(f"{Colors.RED}Failed: {failed}{Colors.NC}")
        print(f"Total: {total}")

        print("\nDetailed Results:")
        for result in self.test_results:
            print(f"  {result}")

        if failed == 0:
            print(f"\n{Colors.GREEN}🎉 All critical tests passed! System is ready for use.{Colors.NC}")
        elif warnings > 0 and failed == 0:
            print(f"\n{Colors.YELLOW}⚠️  System is functional but needs some manual setup.{Colors.NC}")
        else:
            print(f"\n{Colors.RED}❌ Some tests failed. Please review and fix issues.{Colors.NC}")

    def run_all_tests(self):
        """Run all test suites"""
        print(f"{Colors.BLUE}🧪 Starting Rental System Test Suite{Colors.NC}")
        print(f"{Colors.BLUE}Timestamp: {datetime.now().isoformat()}{Colors.NC}")

        if not self.load_terraform_outputs():
            return

        self.test_lambda_function()
        self.test_lex_bot()
        self.test_dynamodb_integration()
        self.test_connect_integration()
        self.test_end_to_end_flow()

        self.print_summary()

if __name__ == "__main__":
    tester = RentalSystemTester()
    tester.run_all_tests()
