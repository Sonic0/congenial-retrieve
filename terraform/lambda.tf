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

##############################################################
# CLOUDWATCH LAMBDA
##############################################################
# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "tbot_RLC_lambda_group" {
  name              = "/aws/lambda/${aws_lambda_function.tbot_RLC_lambda.function_name}"
  retention_in_days = 14
}

##############################################################
# CLOUDWATCH LAMBDA IAM-ROLE
##############################################################
resource "aws_iam_role" "tbot_RLC_lambda_cloudwatch_role" {
  name = "tbot_RLC_lambda_cloudwatch_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

##############################################################
# CLOUDWATCH LAMBDA IAM-POLICY
##############################################################
# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "tbot_RLC_lambda_cloudwatch_logging" {
  name        = "tbot_RLC_lambda_cloudwatch_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

##############################################################
# CLOUDWATCH LAMBDA attach IAM-POLICY to IAM-ROLE
##############################################################
resource "aws_iam_role_policy_attachment" "tbot_RLC_lambda_logs" {
  role       = aws_iam_role.tbot_RLC_lambda_cloudwatch_role.name
  policy_arn = aws_iam_policy.tbot_RLC_lambda_cloudwatch_logging.arn
}