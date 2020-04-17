##############################################################
# DYNAMO-DB TABLE
##############################################################
resource "aws_dynamodb_table" "tbot_RLC_dynamodb" {
  name           = "RLS_user_settings"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "UserId"
  range_key      = "LastRetrieve"

  attribute {
    name = "UserId"
    type = "N"
  }

  attribute {
    name = "Username"
    type = "S"
  }

  attribute {
    name = "Repos"
    type = "S"
  }

  attribute {
    name = "LastRetrieve"
    type = "N"
  }

  global_secondary_index {
    name               = "RLC_Index"
    hash_key           = "UserId"
    range_key          = "Username"
    write_capacity     = 3
    read_capacity      = 3
    projection_type    = "ALL"
  }

  global_secondary_index {
    name               = "RLC_Index2"
    hash_key           = "Username"
    range_key          = "Repos"
    write_capacity     = 3
    read_capacity      = 3
    projection_type    = "KEYS_ONLY"
  }

  tags = {
    Name        = "dynamodb-table-1"
    Environment = "dev"
  }
}