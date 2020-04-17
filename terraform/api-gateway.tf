############################
# INPUT VARIABLES
############################
# Input variable from the Command Line or as Environment variable(export TF_VAR_account_id=xxxxxxxxx)
variable "account_id" {
  type        = string
  description = "The account id related to the used AWS profile"
}


##############################################################
# API-GATEWAY
##############################################################
resource "aws_api_gateway_rest_api" "tbot_RLC_api" {
  name        = "TbotRetriveLastCommit"
  description = "API for Telegram bot retrieve last commit of a project"
}

##############################################################
# API-GATEWAY STAGE
##############################################################
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

##############################################################
# API GATEWAY RESOURCES
##############################################################
# ---- /crittomane ----
resource "aws_api_gateway_resource" "resource" {
  path_part   = "crittomane"
  parent_id   = aws_api_gateway_rest_api.tbot_RLC_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.tbot_RLC_api.id
}

##############################################################
# API-GATEWAY METHODS
##############################################################
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

##############################################################
# API-GATEWAY MODELS
##############################################################
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
