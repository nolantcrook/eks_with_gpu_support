
# S3 Bucket for Knowledge Base Data Sources
resource "aws_s3_bucket" "knowledge_base_data" {
  bucket = "rag-knowledge-base-data-${data.aws_caller_identity.current.account_id}-v2"
}

resource "aws_s3_bucket_versioning" "knowledge_base_data" {
  bucket = aws_s3_bucket.knowledge_base_data.id
  versioning_configuration {
    status = "Disabled"
  }
}
