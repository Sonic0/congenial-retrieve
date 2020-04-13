//create AWS provider 
provider "aws" {
    //aws profile defined in aws cli
  profile = "AWSPersonalProfile" // Decomment this line to use this file locally
    //aws region selection
  region  = "eu-west-1"
}

//create s3 terraform-state location cl
terraform {
  backend "s3"{
    bucket         = "terraf0rm-states-dev" # Change it based on your preferences
    key            = "TbotRetriveLastCommit/terraform.tfstate" # Change it based on your preferences
    dynamodb_table = "terraform_state_lock"
    profile        = "AWSPersonalProfile"
    region         = "eu-west-1"
  }
}
# ------------------------ --------------------- ----------------------

# ---------------------------------------------------------------
# ------------------ LOCALS VARIABLES ---------------------------
locals {
  availability_zone_names = ["eu-west-1"]
}

# ---------------------------------------------------------------
# ------------------- INPUT VARIABLES ---------------------------
# Input variable from the Command Line or as Environment variable(export TF_VAR_account_id=xxxxxxxxx)
variable "account_id" {
  type        = string
  description = "The account id related to the used AWS profile"
}

variable "telegram_bot_token" {
  type        = string
  description = "The Token for the Telegram bot provided by BotFather"
}


# ---------------------------------------------------------------
# ------------------- API GATEWAY -------------------------------
resource "aws_api_gateway_rest_api" "tbot_RLC_api" {
  name        = "TbotRetriveLastCommit"
  description = "API for Telegram bot retrieve last commit of a project"
}

# ------------------------ API STAGES ---------------------------
# ---- DEV ----
resource "aws_api_gateway_stage" "dev" {
  depends_on    = [aws_api_gateway_deployment.dev, aws_api_gateway_resource.resource, aws_cloudwatch_log_group.tbot_RLC_api_group]
  stage_name    = "dev"
  rest_api_id   = aws_api_gateway_rest_api.tbot_RLC_api.id
  deployment_id = aws_api_gateway_deployment.dev.id

  # CloudWatch Stage Log Group
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.tbot_RLC_api_group.arn
    format = "{ \"requestId\": $context.requestId, \"sourceIP\": $context.identity.sourceIp, \"httpMethod\": $context.httpMethod, \"status\": $context.status, \"body\": $input.json('$')}"
  }
}

resource "aws_api_gateway_deployment" "dev" {
  depends_on  = [aws_api_gateway_integration.integration]
  rest_api_id = aws_api_gateway_rest_api.tbot_RLC_api.id
  stage_name  = "dev"
}

# ------------------------ API RESOURCES ---------------------------
# ---- /crittomane ----
resource "aws_api_gateway_resource" "resource" {
  path_part   = "crittomane"
  parent_id   = aws_api_gateway_rest_api.tbot_RLC_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.tbot_RLC_api.id
}

# ------------------------ API METHODS ---------------------------
# ---- POST - /crittomane ----
resource "aws_api_gateway_method" "default-post" {
  rest_api_id   = aws_api_gateway_rest_api.tbot_RLC_api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "POST"
  authorization = "NONE"
  #request_models = { "application/json" = aws_api_gateway_model.tbot_RLC_default-model.name }
  request_validator_id = aws_api_gateway_request_validator.tbot_RLC_all.id
}

resource "aws_api_gateway_method_settings" "settings" {
  rest_api_id = aws_api_gateway_rest_api.tbot_RLC_api.id
  stage_name  = aws_api_gateway_stage.dev.stage_name
  method_path = "${aws_api_gateway_resource.resource.path_part}/${aws_api_gateway_method.default-post.http_method}"

  # CloudWatch Method Log
  settings {
    metrics_enabled         = true
    logging_level           = "INFO"
    data_trace_enabled      = true
    throttling_rate_limit   = 1
    throttling_burst_limit  = 2
  }
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.tbot_RLC_api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.default-post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.tbot_RLC_lambda.invoke_arn
}

# ------------------------ API RESPONSES ---------------------------
# ---- 200 response ----
resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.tbot_RLC_api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.default-post.http_method
  status_code = "200"
}
# ---- 500 response ----
resource "aws_api_gateway_method_response" "response_500" {
  rest_api_id = aws_api_gateway_rest_api.tbot_RLC_api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.default-post.http_method
  status_code = "502"
}

# ---------------------------------------------------------------
# ------------------------ API MODELS ---------------------------
resource "aws_api_gateway_request_validator" "tbot_RLC_all" {
  name                        = "all"
  rest_api_id                 = aws_api_gateway_rest_api.tbot_RLC_api.id
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_model" "tbot_RLC_default-model" {
  rest_api_id  = aws_api_gateway_rest_api.tbot_RLC_api.id
  name         = "firstName"
  description  = "a JSON schema for "
  content_type = "application/json"

  schema = <<EOF
{
  "type": "string"
}
EOF
}

# ---------------------------------------------------------------
# ---------------------- CLOUDWATCH API -------------------------

# ---------------------- api account -------------------------
resource "aws_api_gateway_account" "tbot_RLC_api_account" {
  cloudwatch_role_arn = aws_iam_role.tbot_RLC_api_cloudwatch_role.arn
}

# ---------------------------------------------------------------
# ---------------- CLOUDWATCH API LOG GROUP ---------------------
# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "tbot_RLC_api_group" {
  name              = "/aws/api-gateway/${aws_api_gateway_rest_api.tbot_RLC_api.name}"
  retention_in_days = 14
}

# ---------------------------------------------------------------
# ------------------- API-GATEWAY IAM ROLE ----------------------
resource "aws_iam_role" "tbot_RLC_api_cloudwatch_role" {
  name = "tbot_RLC_api_cloudwatch_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# ---------------------------------------------------------------
# ------------- CLOUDWATCH API IAM POLICY & ATTACH --------------
resource "aws_iam_role_policy" "tbot_RLC_api_cloudwatch_logging" {
  name = "tbot_RLC_api_cloudwatch_logging"
  role = aws_iam_role.tbot_RLC_api_cloudwatch_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# ---------------------------------------------------------------
# ------------- LAMBDA INVOKE PERMISSION ------------------------
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tbot_RLC_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${local.availability_zone_names[0]}:${var.account_id}:${aws_api_gateway_rest_api.tbot_RLC_api.id}/*/${aws_api_gateway_method.default-post.http_method}${aws_api_gateway_resource.resource.path}"
}

# ---------------------------------------------------------------
# ------------------------ LAMBDA -------------------------------
resource "aws_lambda_function" "tbot_RLC_lambda" {
  filename      = "tbot-lambda/lambda.zip"
  function_name = "tbot_RLC_lambda"
  memory_size   = 128
  role          = aws_iam_role.tbot_RLC_lambda_cloudwatch_role.arn
  #depends_on    = [aws_iam_role_policy_attachment.tbot_RLC_lambda_logs,aws_cloudwatch_log_group.tbot_RLC_lambda_group]
  depends_on    = [aws_iam_role_policy_attachment.tbot_RLC_lambda_logs]
  handler       = "tbot_RLC_lambda.main"
  runtime       = "provided" # Does not exists a specific runtime for Rust

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  source_code_hash = filebase64sha256("tbot-lambda/lambda.zip")

  environment {
    variables = {
      TELEGRAM_BOT_TOKEN = var.telegram_bot_token,
      DYNAMO_TABLE_NAME = aws_dynamodb_table.tbot_RLC_dynamodb.name,
      RUST_BACKTRACE = 1
    }
  }
}

# ---------------------------------------------------------------
# ------------------- CLOUDWATCH LAMBDA -------------------------
# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "tbot_RLC_lambda_group" {
  name              = "/aws/lambda/${aws_lambda_function.tbot_RLC_lambda.function_name}"
  retention_in_days = 14
}

# ---------------------------------------------------------------
# ------------------- LAMBDA IAM ROLE ---------------------------
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

# ---------------------------------------------------------------
# ----------------- CLOUDWATCH LAMBDA IAM -----------------------
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
# Attach Policy to te Role
resource "aws_iam_role_policy_attachment" "tbot_RLC_lambda_logs" {
  role       = aws_iam_role.tbot_RLC_lambda_cloudwatch_role.name
  policy_arn = aws_iam_policy.tbot_RLC_lambda_cloudwatch_logging.arn
}

# ---------------------------------------------------------------
# -------------------- DYNAMO DB TABLE --------------------------
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

//# ---------------------------------------------------------------
//# --------------------------- VPC -------------------------------
//
//# create VPC
//resource "aws_vpc" "TbotRetriveLastCommitVPC" {
//  cidr_block           = "20.0.0.0/24"
//  instance_tenancy     = "default"
//  enable_dns_hostnames = "true"
//  tags = {
//    Name = "TerraformTest-VPC"
//  }
//}
//
////create Internet Gateway
//resource "aws_internet_gateway" "TbotRetriveLastCommitIGW" {
//  vpc_id = aws_vpc.TbotRetriveLastCommitVPC.id
//
//  tags = {
//    Name = "TbotRetriveLastCommitIGW"
//  }
//}
