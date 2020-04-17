############################
# INPUT VARIABLES
############################
variable "telegram_bot_token" {
  type        = string
  description = "The Token for the Telegram bot provided by BotFather"
}

##############################################################
# LAMBDA INVOKE PERMISSION
##############################################################
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tbot_RLC_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${local.availability_zone_names[0]}:${var.account_id}:${aws_api_gateway_rest_api.tbot_RLC_api.id}/*/${aws_api_gateway_method.default-post.http_method}${aws_api_gateway_resource.resource.path}"
}

##############################################################
# LAMBDA
##############################################################
resource "aws_lambda_function" "tbot_RLC_lambda" {
  filename      = "../lambda.zip"
  function_name = "tbot_RLC_lambda"
  memory_size   = 128
  role          = aws_iam_role.tbot_RLC_lambda_cloudwatch_role.arn
  #depends_on    = [aws_iam_role_policy_attachment.tbot_RLC_lambda_logs,aws_cloudwatch_log_group.tbot_RLC_lambda_group]
  depends_on    = [aws_iam_role_policy_attachment.tbot_RLC_lambda_logs]
  handler       = "tbot_RLC_lambda.main"
  runtime       = "provided" # Does not exists a specific runtime for Rust

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  source_code_hash = filebase64sha256("../lambda.zip")

  environment {
    variables = {
      TELEGRAM_BOT_TOKEN = var.telegram_bot_token,
      DYNAMO_TABLE_NAME = aws_dynamodb_table.tbot_RLC_dynamodb.name,
      RUST_BACKTRACE = 1
    }
  }
}
