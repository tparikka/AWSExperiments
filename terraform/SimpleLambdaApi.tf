locals {
  resource_name_prefix          = "${local.prefix}-simple-lambda-api"
  lambda_code_path              = "${path.module}/../src/SimpleLambdaApi/bin/Release/net6.0/linux-x64"
  lambda_archive_path           = "${path.module}/../src/SimpleLambdaApi.zip"
  lambda_handler                = "SimpleLambdaApi"
  lambda_description            = "This is simple Lambda API"
  lambda_runtime                = "dotnet6"
  lambda_region                 = "us-east-1"
  lambda_timeout                = 30
  lambda_concurrent_executions  = -1
  lambda_cw_log_group_name      = "/aws/lambda/${aws_lambda_function.simple_lambda_api.function_name}"
  lambda_log_retention_in_days  = 1
}

data "archive_file" "simple_lambda_api_zip" {
  source_dir = local.lambda_code_path
  output_path = local.lambda_archive_path
  type = "zip"
}

data "aws_iam_policy_document" "simple_lambda_api_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "simple_lambda_api" {
  name = "${local.resource_name_prefix}-role"
  assume_role_policy = data.aws_iam_policy_document.simple_lambda_api_assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
  tags = merge(
    {
      Name = "${local.resource_name_prefix}-role"
    },
    local.common_tags
  )
}

resource "aws_lambda_function" "simple_lambda_api" {
  function_name = "${local.resource_name_prefix}-lambda"
  source_code_hash = data.archive_file.simple_lambda_api_zip.output_base64sha256
  filename = data.archive_file.simple_lambda_api_zip.output_path
  description = local.lambda_description
  role          = aws_iam_role.simple_lambda_api.arn
  handler = local.lambda_handler
  runtime = local.lambda_runtime
  timeout = local.lambda_timeout
  tags = merge(
    {
      Name = "${local.resource_name_prefix}-lambda"
    },
    local.common_tags
  )
  reserved_concurrent_executions = local.lambda_concurrent_executions
}

resource "aws_lambda_function_url" "test_latest" {
  function_name      = "${local.resource_name_prefix}-lambda"
  authorization_type = "NONE"
}

resource "aws_cloudwatch_log_group" "simple_lambda_api" {
  name = local.lambda_cw_log_group_name
  retention_in_days = local.lambda_log_retention_in_days
}