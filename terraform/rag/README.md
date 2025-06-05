# Bedrock Knowledge Base Terraform Configuration

This Terraform configuration creates a complete Amazon Bedrock Knowledge Base setup that replicates the existing knowledge base `DFVMT0Y6LF`.

## Architecture

The configuration creates:

1. **Amazon Bedrock Knowledge Base** - Vector-based knowledge base using Amazon Titan Embed Text v2
2. **OpenSearch Serverless Collection** - Vector storage for embeddings
3. **S3 Bucket** - Data source storage for documents
4. **IAM Roles and Policies** - Proper permissions for Bedrock to access resources
5. **Security Policies** - OpenSearch Serverless encryption and network policies

## Resources Created

### Core Resources
- `aws_bedrockagent_knowledge_base.main` - The main knowledge base
- `aws_bedrockagent_data_source.s3_data_source` - S3 data source configuration
- `aws_opensearchserverless_collection.knowledge_base` - Vector search collection
- `aws_s3_bucket.knowledge_base_data` - Document storage bucket

### Security & Access
- `aws_iam_role.bedrock_knowledge_base_role` - Service role for the knowledge base
- `aws_opensearchserverless_security_policy` - Encryption and network policies
- `aws_opensearchserverless_access_policy` - Data access permissions

## Configuration Details

### Embedding Model
- **Model**: Amazon Titan Embed Text v2 (`amazon.titan-embed-text-v2:0`)
- **Dimensions**: 1024
- **Type**: Vector-based knowledge base

### Vector Store
- **Type**: OpenSearch Serverless
- **Collection Type**: VECTORSEARCH
- **Index Name**: `bedrock-knowledge-base-default-index`
- **Vector Field**: `bedrock-knowledge-base-default-vector`
- **Text Field**: `AMAZON_BEDROCK_TEXT`
- **Metadata Field**: `AMAZON_BEDROCK_METADATA`

## Deployment

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Plan the deployment**:
   ```bash
   terraform plan
   ```

3. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## Usage

### Adding Documents

1. Upload documents to the S3 bucket created by this configuration
2. Sync the data source to ingest the documents:
   ```bash
   aws bedrock-agent start-ingestion-job \
     --knowledge-base-id <knowledge-base-id> \
     --data-source-id <data-source-id> \
     --region us-west-2
   ```

### Querying the Knowledge Base

Use the knowledge base ID in your applications or with the Bedrock Agent:

```python
import boto3

bedrock_agent = boto3.client('bedrock-agent-runtime', region_name='us-west-2')

response = bedrock_agent.retrieve(
    knowledgeBaseId='<knowledge-base-id>',
    retrievalQuery={
        'text': 'Your query here'
    }
)
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region to deploy resources | `us-west-2` |
| `environment` | Environment name | `dev` |
| `tags` | Tags to apply to all resources | `{Environment: "dev", Project: "graphrag"}` |

## Outputs

| Output | Description |
|--------|-------------|
| `knowledge_base_id` | ID of the Bedrock Knowledge Base |
| `knowledge_base_arn` | ARN of the Bedrock Knowledge Base |
| `opensearch_serverless_collection_arn` | ARN of the OpenSearch Serverless collection |
| `s3_data_bucket_name` | Name of the S3 bucket for documents |
| `data_source_id` | ID of the Knowledge Base data source |

## Notes

- The configuration uses OpenSearch Serverless instead of managed OpenSearch for better scalability and cost optimization
- The S3 bucket name includes a random suffix to ensure uniqueness
- All resources are tagged according to the `tags` variable
- The IAM role has minimal required permissions for security

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete the knowledge base and all associated data.
