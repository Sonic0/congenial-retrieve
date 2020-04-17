########################################################################################
#------------------------- CLOUDWATCH API-GATEWAY -------------------------------------#
########################################################################################

##############################################################
# API-GATEWAY ACCOUNT
##############################################################
resource "aws_api_gateway_account" "tbot_RLC_api_account" {
  cloudwatch_role_arn = aws_iam_role.tbot_RLC_api_cloudwatch_role.arn
}

##############################################################
# CLOUDWATCH API-GATEWAY LOG GROUP
##############################################################
# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "tbot_RLC_api_group" {
  name              = "/aws/api-gateway/${aws_api_gateway_rest_api.tbot_RLC_api.name}"
  retention_in_days = 14
}

# ---------------------------------------------------------------
# ------------------- API-GATEWAY IAM ROLE ----------------------
##############################################################
# CLOUDWATCH API-GATEWAY IAM ROLE
##############################################################
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


########################################################################################
#------------------------------ CLOUDWATCH LAMBDA -------------------------------------#
########################################################################################

##############################################################
# CLOUDWATCH LAMBDA GROUP
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
