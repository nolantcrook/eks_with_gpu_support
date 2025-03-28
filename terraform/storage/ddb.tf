resource "aws_dynamodb_table" "generate_image_status" {
  name         = "generate_image_status"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "MessageId"

  attribute {
    name = "MessageId"
    type = "S"
  }
}

resource "aws_dynamodb_table" "invokeai_auth_codes" {
  name         = "invokeai_auth_codes"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "code"

  attribute {
    name = "code"
    type = "S"
  }
}
