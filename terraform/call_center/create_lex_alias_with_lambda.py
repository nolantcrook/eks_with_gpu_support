#!/usr/bin/env python3
"""
Script to create or update Lex V2 bot alias with Lambda code hook
"""

import boto3
import os
import sys
from botocore.exceptions import ClientError

def create_or_update_lex_alias():
    """Create or update Lex bot alias with Lambda code hook"""

    # Get environment variables
    bot_id = os.environ.get("LEX_BOT_ID")
    alias_name = os.environ.get("LEX_ALIAS_NAME", "TestBotAlias")
    lambda_arn = os.environ.get("LAMBDA_ARN")

    if not bot_id:
        print("❌ LEX_BOT_ID environment variable not set")
        sys.exit(1)

    if not lambda_arn:
        print("❌ LAMBDA_ARN environment variable not set")
        sys.exit(1)

    print(f"🔧 Configuring Lex bot alias...")
    print(f"   Bot ID: {bot_id}")
    print(f"   Alias Name: {alias_name}")
    print(f"   Lambda ARN: {lambda_arn}")

    try:
        lex_client = boto3.client('lexv2-models')

        # Check if alias already exists
        try:
            aliases_response = lex_client.list_bot_aliases(botId=bot_id)
            existing_alias = None

            for alias in aliases_response['botAliasSummaries']:
                if alias['botAliasName'] == alias_name:
                    existing_alias = alias
                    break

            # Configure locale settings with Lambda code hook
            locale_settings = {
                'en_US': {
                    'enabled': True,
                    'codeHookSpecification': {
                        'lambdaCodeHook': {
                            'lambdaARN': lambda_arn,
                            'codeHookInterfaceVersion': '1.0'
                        }
                    }
                }
            }

            if existing_alias:
                print(f"📝 Updating existing alias: {alias_name} ({existing_alias['botAliasId']})")

                # Update the existing alias
                response = lex_client.update_bot_alias(
                    botId=bot_id,
                    botAliasId=existing_alias['botAliasId'],
                    botAliasName=alias_name,
                    botVersion='DRAFT',
                    botAliasLocaleSettings=locale_settings
                )

                print(f"✅ Alias updated successfully")
                print(f"   Alias ID: {response['botAliasId']}")
                print(f"   Status: {response['botAliasStatus']}")

            else:
                print(f"🆕 Creating new alias: {alias_name}")

                # Create new alias
                response = lex_client.create_bot_alias(
                    botId=bot_id,
                    botAliasName=alias_name,
                    botVersion='DRAFT',
                    botAliasLocaleSettings=locale_settings
                )

                print(f"✅ Alias created successfully")
                print(f"   Alias ID: {response['botAliasId']}")
                print(f"   Status: {response['botAliasStatus']}")

            # Verify the configuration
            print(f"\n🔍 Verifying configuration...")
            verify_response = lex_client.describe_bot_alias(
                botId=bot_id,
                botAliasId=response['botAliasId']
            )

            locale_settings_verify = verify_response.get('botAliasLocaleSettings', {})
            if 'en_US' in locale_settings_verify:
                en_us_settings = locale_settings_verify['en_US']
                if 'codeHookSpecification' in en_us_settings:
                    lambda_hook = en_us_settings['codeHookSpecification'].get('lambdaCodeHook', {})
                    if lambda_hook.get('lambdaARN') == lambda_arn:
                        print("✅ Lambda code hook configured correctly")
                    else:
                        print("❌ Lambda code hook not configured correctly")
                        sys.exit(1)
                else:
                    print("❌ No code hook specification found")
                    sys.exit(1)
            else:
                print("❌ No en_US locale settings found")
                sys.exit(1)

            print(f"\n🎉 Lex bot alias configuration completed successfully!")

        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == 'ResourceNotFoundException':
                print(f"❌ Bot not found: {bot_id}")
            elif error_code == 'ValidationException':
                print(f"❌ Validation error: {e}")
            else:
                print(f"❌ Error: {e}")
            sys.exit(1)

    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    create_or_update_lex_alias()
