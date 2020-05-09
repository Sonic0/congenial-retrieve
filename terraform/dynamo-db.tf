##############################################################
# DYNAMO-DB TABLE
##############################################################
resource "aws_dynamodb_table" "tbot_RLC_dynamodb" {
  name           = "RLS_user_settings"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "UserId"
  range_key      = "Repo"

  attribute {
    name = "UserId"
    type = "N"
  }

  attribute {
    name = "Repo"
    type = "S"
  }

  timeouts {
    create = "3m"
    update = "1m"
    delete = "1m"
  }

  tags = {
    Name        = "telegram-bot-table"
    Environment = "dev"
  }
}