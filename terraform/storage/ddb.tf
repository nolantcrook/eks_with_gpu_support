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

resource "aws_dynamodb_table" "hauliday_reservations" {
  name         = "hauliday_reservations"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "reservation_id"
  range_key    = "start_date"

  attribute {
    name = "reservation_id"
    type = "S"
  }

  attribute {
    name = "start_date"
    type = "S"
  }

  attribute {
    name = "equipment_id"
    type = "S"
  }

  global_secondary_index {
    name            = "EquipmentDateIndex"
    hash_key        = "equipment_id"
    range_key       = "start_date"
    projection_type = "ALL"
  }

  tags = {
    Name        = "Hauliday Reservations"
    Environment = "production"
    Service     = "hauliday"
  }
}
