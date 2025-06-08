#!/usr/bin/env python3
import boto3
import json
import sys
import time
from opensearchpy import OpenSearch, RequestsHttpConnection
from aws_requests_auth.aws_auth import AWSRequestsAuth

def create_opensearch_index(collection_endpoint, index_name, region='us-west-2'):
    """Create OpenSearch index with proper mapping for Bedrock Knowledge Base"""

    # Get AWS credentials
    session = boto3.Session()
    credentials = session.get_credentials()

    # Create auth object
    auth = AWSRequestsAuth(
        aws_access_key=credentials.access_key,
        aws_secret_access_key=credentials.secret_key,
        aws_token=credentials.token,
        aws_host=collection_endpoint.replace('https://', ''),
        aws_region=region,
        aws_service='aoss'
    )

    # Create OpenSearch client
    client = OpenSearch(
        hosts=[{'host': collection_endpoint.replace('https://', ''), 'port': 443}],
        http_auth=auth,
        use_ssl=True,
        verify_certs=True,
        connection_class=RequestsHttpConnection,
        timeout=60
    )

    # Index mapping for Bedrock Knowledge Base
    index_mapping = {
        "settings": {
            "index": {
                "number_of_shards": 2,
                "number_of_replicas": 0,
                "knn": True,
                "knn.algo_param.ef_search": 512
            }
        },
        "mappings": {
            "dynamic_templates": [
                {
                    "strings_as_keyword": {
                        "match_mapping_type": "string",
                        "mapping": {
                            "type": "keyword"
                        }
                    }
                }
            ],
            "properties": {
                "AMAZON_BEDROCK_METADATA": {
                    "type": "text",
                    "index": False
                },
                "AMAZON_BEDROCK_TEXT": {
                    "type": "text",
                    "analyzer": "standard"
                },
                "AMAZON_BEDROCK_TEXT_CHUNK": {
                    "type": "text",
                    "analyzer": "standard"
                },
                "bedrock-knowledge-base-v3-vector": {
                    "type": "knn_vector",
                    "dimension": 1024,
                    "method": {
                        "name": "hnsw",
                        "space_type": "l2",
                        "engine": "faiss",
                        "parameters": {
                            "ef_construction": 512,
                            "m": 16
                        }
                    }
                },
                "id": {
                    "type": "text",
                    "fields": {
                        "keyword": {
                            "type": "keyword",
                            "ignore_above": 256
                        }
                    }
                },
                "x-amz-bedrock-kb-data-source-id": {
                    "type": "text",
                    "fields": {
                        "keyword": {
                            "type": "keyword",
                            "ignore_above": 256
                        }
                    }
                },
                "x-amz-bedrock-kb-source-uri": {
                    "type": "text",
                    "fields": {
                        "keyword": {
                            "type": "keyword",
                            "ignore_above": 256
                        }
                    }
                }
            }
        }
    }

    try:
        # Check if index exists
        if client.indices.exists(index=index_name):
            print(f"Index {index_name} already exists. Deleting...")
            client.indices.delete(index=index_name)
            time.sleep(5)

        # Create the index
        print(f"Creating index {index_name}...")
        response = client.indices.create(
            index=index_name,
            body=index_mapping
        )

        print(f"Index created successfully: {json.dumps(response, indent=2)}")
        return True

    except Exception as e:
        print(f"Error creating index: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python create_index.py <collection_endpoint> <index_name>")
        sys.exit(1)

    collection_endpoint = sys.argv[1]
    index_name = sys.argv[2]

    success = create_opensearch_index(collection_endpoint, index_name)
    sys.exit(0 if success else 1)
