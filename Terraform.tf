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

# locals variables
locals {
  availability_zone_names = ["eu-west-1"]
}

# Input variable from the Command Line or as Environment variable(export TF_VAR_account_id=xxxxxxxxx)
variable "account_id" {
  type        = string
  description = "The account id related to the used AWS profile"
}

# ---------------------------------------------------------------
# ------------------- API GATEWAY -------------------------------
resource "aws_api_gateway_stage" "dev" {
  stage_name    = "dev"
  rest_api_id   = aws_api_gateway_rest_api.tbot_RLC_api.id
  deployment_id = aws_api_gateway_deployment.dev.id
}

resource "aws_api_gateway_rest_api" "tbot_RLC_api" {
  name        = "TbotRetriveLastCommit"
  description = "API for Telegram bot retrieve last commit of a project"
}

resource "aws_api_gateway_deployment" "dev" {
  depends_on  = [aws_api_gateway_integration.integration]
  rest_api_id = aws_api_gateway_rest_api.tbot_RLC_api.id
  stage_name  = "dev"
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "repos"
  parent_id   = aws_api_gateway_rest_api.tbot_RLC_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.tbot_RLC_api.id
}

resource "aws_api_gateway_method" "repos-post" {
  rest_api_id   = aws_api_gateway_rest_api.tbot_RLC_api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "repos-get" {
  rest_api_id   = aws_api_gateway_rest_api.tbot_RLC_api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_settings" "s" {
  rest_api_id = aws_api_gateway_rest_api.tbot_RLC_api.id
  stage_name  = aws_api_gateway_stage.dev.stage_name
  method_path = "${aws_api_gateway_resource.resource.path_part}/${aws_api_gateway_method.repos-post.http_method}"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.tbot_RLC_api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.repos-post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.tbot_RLC_lambda.invoke_arn
}

# ---------------------------------------------------------------
# ------------- LAMBDA INVOKE PERMISSION ------------------------
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tbot_RLC_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${local.availability_zone_names[0]}:${var.account_id}:${aws_api_gateway_rest_api.tbot_RLC_api.id}/*/${aws_api_gateway_method.repos-post.http_method}${aws_api_gateway_resource.resource.path}"
}

# ---------------------------------------------------------------
# ------------------------ LAMBDA -------------------------------
resource "aws_lambda_function" "tbot_RLC_lambda" {
  filename      = "tbot-lambda/lambda.zip"
  function_name = "tbot_RLC_lambda"
  role          = aws_iam_role.tbot_RLC_lambda_role.arn
  #depends_on    = [aws_iam_role_policy_attachment.tbot_RLC_lambda_logs,aws_cloudwatch_log_group.tbot_RLC_lambda_group]
  depends_on    = [aws_iam_role_policy_attachment.tbot_RLC_lambda_logs]
  handler       = "tbot_RLC_lambda.main"
  runtime       = "provided"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  source_code_hash = filebase64sha256("lambda.zip")

  environment {
    variables = {
      RUST_BACKTRACE = 1
    }
  }
}

# ---------------------------------------------------------------
# ------------------- LAMBDA IAM ROLE ---------------------------
resource "aws_iam_role" "tbot_RLC_lambda_role" {
  name = "tbot_RLC_lambda_role"

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
# ------------------- CLOUDWATCH LAMBDA -------------------------
# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "tbot_RLC_lambda_group" {
  name              = "/aws/lambda/${aws_lambda_function.tbot_RLC_lambda.function_name}"
  retention_in_days = 14
}

# ---------------------------------------------------------------
# ----------------- CLOUDWATCH LAMBDA IAM -----------------------
# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "tbot_RLC_lambda_logging" {
  name        = "lambda_logging"
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

resource "aws_iam_role_policy_attachment" "tbot_RLC_lambda_logs" {
  role       = aws_iam_role.tbot_RLC_lambda_role.name
  policy_arn = aws_iam_policy.tbot_RLC_lambda_logging.arn
}


# ---------------------------------------------------------------
# --------------------------- VPC -------------------------------

# create VPC
resource "aws_vpc" "TbotRetriveLastCommitVPC" {
  cidr_block           = "20.0.0.0/24"
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"
  tags = {
    Name = "TerraformTest-VPC"
  }
}

//create Internet Gateway
resource "aws_internet_gateway" "TbotRetriveLastCommitIGW" {
  vpc_id = aws_vpc.TbotRetriveLastCommitVPC.id

  tags = {
    Name = "TbotRetriveLastCommitIGW"
  }
}
