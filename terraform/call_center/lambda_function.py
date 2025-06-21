import json
import boto3
import os
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize Bedrock client
bedrock_agent_runtime = boto3.client('bedrock-agent-runtime')

def lambda_handler(event, context):
    """
    Lambda function to handle Lex intents and query Bedrock Knowledge Base
    """
    logger.info(f"Received event: {json.dumps(event)}")

    try:
        # Extract information from Lex event
        intent_name = event['sessionState']['intent']['name']
        slots = event['sessionState']['intent']['slots']

        # Get the user's query - try multiple sources
        user_query = ""

        # First, try to get from slots (if they exist)
        query_slot = slots.get('query', {})
        if query_slot:
            user_query = query_slot.get('value', {}).get('interpretedValue', '')

        # If no slot value, try to get from input transcript
        if not user_query and 'inputTranscript' in event:
            user_query = event['inputTranscript']

        # If still no query, try to get from session attributes or other sources
        if not user_query:
            session_attributes = event.get('sessionState', {}).get('sessionAttributes', {})
            user_query = session_attributes.get('userQuery', '')

        if not user_query:
            return create_lex_response(
                "I didn't catch your question. Could you please repeat what you'd like to know about our knowledge base?",
                'Failed'
            )

        logger.info(f"User query: {user_query}")

        # Query the Bedrock Knowledge Base
        knowledge_base_response = query_knowledge_base(user_query)

        if knowledge_base_response:
            response_text = knowledge_base_response
        else:
            response_text = "I'm sorry, I couldn't find information about that in our knowledge base. Could you try rephrasing your question?"

        return create_lex_response(response_text, 'Fulfilled')

    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return create_lex_response(
            "I'm sorry, I'm having trouble processing your request right now. Please try again later.",
            'Failed'
        )

def query_knowledge_base(query):
    """
    Query the Bedrock Knowledge Base using RetrieveAndGenerate
    """
    try:
        knowledge_base_id = os.environ.get('KNOWLEDGE_BASE_ID')
        model_id = os.environ.get('MODEL_ID', 'anthropic.claude-3-sonnet-20240229-v1:0')

        if not knowledge_base_id:
            logger.error("KNOWLEDGE_BASE_ID environment variable not set")
            return None

        logger.info(f"Querying knowledge base {knowledge_base_id} with query: {query}")

        response = bedrock_agent_runtime.retrieve_and_generate(
            input={
                'text': query
            },
            retrieveAndGenerateConfiguration={
                'type': 'KNOWLEDGE_BASE',
                'knowledgeBaseConfiguration': {
                    'knowledgeBaseId': knowledge_base_id,
                    'modelArn': f'arn:aws:bedrock:us-west-2::foundation-model/{model_id}'
                }
            }
        )

        # Extract the generated text from the response
        generated_text = response.get('output', {}).get('text', '')

        logger.info(f"Knowledge base response: {generated_text}")

        return generated_text

    except Exception as e:
        logger.error(f"Error querying knowledge base: {str(e)}")
        return None

def create_lex_response(message, fulfillment_state):
    """
    Create a properly formatted Lex response
    """
    return {
        'sessionState': {
            'dialogAction': {
                'type': 'Close'
            },
            'intent': {
                'name': 'KnowledgeQueryIntent',
                'state': fulfillment_state
            }
        },
        'messages': [
            {
                'contentType': 'PlainText',
                'content': message
            }
        ]
    }
