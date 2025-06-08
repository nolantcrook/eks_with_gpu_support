# RAG Knowledge Base Infrastructure

This Terraform configuration creates a complete RAG (Retrieval Augmented Generation) infrastructure using AWS Bedrock Knowledge Base and OpenSearch Serverless.

## Architecture

- **AWS Bedrock Knowledge Base**: Vector database for document embeddings
- **OpenSearch Serverless**: Vector search engine with proper index mapping
- **S3 Bucket**: Storage for source documents
- **IAM Roles**: Proper permissions for Bedrock to access resources
- **CloudWatch Logs**: Monitoring and debugging

## Features

- ✅ Proper OpenSearch index mapping for Bedrock compatibility
- ✅ Automated index creation with correct vector field configuration
- ✅ Automatic ingestion after infrastructure deployment
- ✅ Configurable ingestion timeout and auto-start behavior
- ✅ Comprehensive outputs for integration

## Quick Start

1. **Deploy the infrastructure:**
   ```bash
   terragrunt apply
   ```

2. **The system will automatically:**
   - Create the OpenSearch collection and index
   - Set up the Bedrock Knowledge Base
   - Create the S3 data source
   - Start ingestion of documents from S3
   - Wait for ingestion completion

3. **Test the knowledge base:**
   ```bash
   python3 test_queries.py
   ```

## Configuration Variables

| Variable | Description | Default | Type |
|----------|-------------|---------|------|
| `aws_region` | AWS region to deploy resources | `us-west-2` | string |
| `knowledge_base_name` | Name of the Bedrock knowledge base | `rag-knowledge-base-v3` | string |
| `auto_start_ingestion` | Whether to automatically start ingestion after creation | `true` | bool |
| `ingestion_timeout_minutes` | Timeout for automatic ingestion in minutes | `30` | number |
| `tags` | Tags to apply to all resources | `{Environment = "dev", Project = "graphrag"}` | map(string) |

## Auto-Ingestion Feature

The infrastructure includes automatic ingestion that:

- **Triggers after** knowledge base and data source creation
- **Monitors progress** with real-time status updates
- **Waits for completion** before Terraform finishes
- **Reports statistics** on documents processed
- **Can be disabled** by setting `auto_start_ingestion = false`

### Controlling Auto-Ingestion

```hcl
# Disable auto-ingestion
auto_start_ingestion = false

# Increase timeout for large document sets
ingestion_timeout_minutes = 60
```

### Manual Ingestion

If auto-ingestion is disabled or you need to re-ingest:

```bash
# Using the provided script
python3 auto_ingestion.py <knowledge_base_id> <data_source_id> --timeout 30

# Using AWS CLI
aws bedrock-agent start-ingestion-job \
  --knowledge-base-id <knowledge_base_id> \
  --data-source-id <data_source_id>
```

## Outputs

After deployment, you'll get:

- `knowledge_base_id`: For querying the knowledge base
- `data_source_id`: For managing data sources
- `opensearch_collection_endpoint`: For direct OpenSearch access
- `s3_bucket_name`: For uploading documents
- `auto_ingestion_status`: Status of automatic ingestion

## Testing

Several test scripts are provided:

```bash
# Test the new knowledge base
python3 test_queries.py

# Compare with working knowledge base
python3 test_working_kb.py

# Manual ingestion control
python3 start_ingestion.py
```

## Troubleshooting

### Ingestion Issues
- Check CloudWatch logs for detailed error messages
- Verify S3 bucket permissions and document format
- Ensure documents are in the correct S3 prefix (`knowledgebase-demo/`)

### Index Mapping Issues
- The infrastructure automatically creates the correct index mapping
- If issues persist, check OpenSearch collection logs

### Timeout Issues
- Increase `ingestion_timeout_minutes` for large document sets
- Monitor ingestion progress in AWS Console

## Cleanup

To destroy the infrastructure:

```bash
# Standard cleanup
terragrunt destroy

# If S3 bucket has data you want to keep
terraform state rm aws_s3_bucket.knowledge_base_data
terraform state rm aws_s3_bucket_versioning.knowledge_base_data
terragrunt destroy
```
