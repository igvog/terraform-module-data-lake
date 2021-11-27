data "archive_file" "lambda_function_zip" {
  count = var.lambda_function_enable ? 1 : 0

  type             = "zip"
  source_dir       = "${path.module}/../../lambda"
  output_file_mode = "0666"
  output_path      = "${path.module}/files/${local.full_name}.zip"
}

data "assert_test" "lambda_size" {
  count = var.lambda_function_enable ? 1 : 0

  test  = (local.lambda_function_zip_size < 50 && var.lambda_function.s3_bucket != null)
  throw = "Lambda ZIP archive size > 50 Mb. Please set 's3_bucket' variable."
}

resource "aws_s3_bucket_object" "lambda_function_zip_upload" {
  count = (var.lambda_function_enable &&
  var.lambda_function.s3_bucket != null) ? 1 : 0

  bucket = var.lambda_function.s3_bucket
  key    = "${local.full_name}.zip"
  source = "${path.module}/files/${local.full_name}.zip"
  etag   = "${filemd5("${path.module}/files/${local.full_name}.zip")}"
}

resource "aws_lambda_function" "lambda_function" {
  count = var.lambda_function_enable ? 1 : 0

  function_name = local.full_name
  role          = var.lambda_function.role

  handler = var.lambda_function.handler != null ? var.lambda_function.handler : "lambda_handler"
  runtime = var.lambda_function.runtime != null ? var.lambda_function.runtime : "python3.9"

  filename                       = var.lambda_function.s3_bucket == null ? "${path.module}/files/${local.full_name}.zip" : null
  s3_bucket                      = var.lambda_function.s3_bucket != null ? var.lambda_function.s3_bucket : null
  s3_key                         = var.lambda_function.s3_bucket != null ? "${local.full_name}.zip" : null
  s3_object_version              = var.lambda_function.s3_object_version != null ? var.lambda_function.s3_object_version : null
  description                    = var.lambda_function.description
  layers                         = var.lambda_function.layers
  memory_size                    = var.lambda_function.memory_size
  timeout                        = var.lambda_function.timeout
  reserved_concurrent_executions = var.lambda_function.reserved_concurrent_executions
  publish                        = var.lambda_function.publish
  kms_key_arn                    = var.lambda_function.kms_key_arn
  source_code_hash               = var.lambda_function.source_code_hash

  dynamic "dead_letter_config" {
    iterator = dead_letter_config
    for_each = var.lambda_function.dead_letter_config != null ? var.lambda_function.dead_letter_config : []

    content {
      target_arn = lookup(dead_letter_config.value, "target_arn", null)
    }
  }

  dynamic "tracing_config" {
    iterator = tracing_config
    for_each = var.lambda_function.tracing_config != null ? var.lambda_function.tracing_config : []

    content {
      mode = lookup(tracing_config.value, "mode", null)
    }
  }

  dynamic "vpc_config" {
    iterator = vpc_config
    for_each = var.lambda_function.vpc_config != null ? var.lambda_function.vpc_config : []

    content {
      subnet_ids         = lookup(vpc_config.value, "subnet_ids", null)
      security_group_ids = lookup(vpc_config.value, "security_group_ids", null)
    }
  }

  dynamic "environment" {
    for_each = var.lambda_function.environment == null ? [] : [var.lambda_function.environment]

    content {
      variables = var.lambda_function.environment
    }
  }

  dynamic "timeouts" {
    iterator = timeouts
    for_each = var.lambda_function.timeouts != null ? var.lambda_function.timeouts : []

    content {
      create = lookup(timeouts.value, "create", null)
    }
  }

  tags = merge(
    {
      App = "lambda"
    },
    local.base_tags,
    var.tags
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = [
    data.archive_file.lambda_function_zip,
    aws_s3_bucket_object.lambda_function_zip_upload
  ]
}


// API Gateway integration
//
resource "aws_api_gateway_rest_api" "lambda_api_gateway_rest_api" {
  count = var.lambda_function_enable && var.lambda_function_api_gateway ? 1 : 0

  name = "${local.full_name}-lambda"

  description = "API Gateway for trigger lambda - ${local.full_name}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(
    {
      App = "api-gateway"
    },
    local.base_tags,
    var.tags
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = [aws_lambda_function.lambda_function]
}

resource "aws_lambda_permission" "lambda_permission" {
  count = var.lambda_function_enable && var.lambda_function_api_gateway ? 1 : 0

  action        = "lambda:InvokeFunction"
  function_name = local.full_name
  principal     = "apigateway.amazonaws.com"

  source_arn   = aws_api_gateway_rest_api.lambda_api_gateway_rest_api[0].arn
  statement_id = "AllowAPIGatewayInvoke"

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = [
    aws_lambda_function.lambda_function,
    aws_api_gateway_rest_api.lambda_api_gateway_rest_api,
  ]
}

// "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.lambda_api_gateway_rest_api[0].id}/prod/POST/"

resource "aws_api_gateway_resource" "lambda_api_gateway_resource" {
  count = var.lambda_function_enable && var.lambda_function_api_gateway ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.lambda_api_gateway_rest_api[0].id
  parent_id   = aws_api_gateway_rest_api.lambda_api_gateway_rest_api[0].root_resource_id
  path_part   = var.name

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = [aws_api_gateway_rest_api.lambda_api_gateway_rest_api]
}

resource "aws_api_gateway_method" "lambda_api_gateway_method" {
  count = var.lambda_function_enable && var.lambda_function_api_gateway ? 1 : 0

  rest_api_id   = aws_api_gateway_rest_api.lambda_api_gateway_rest_api[0].id
  resource_id   = aws_api_gateway_resource.lambda_api_gateway_resource[0].id
  http_method   = "POST"
  authorization = "NONE"

  api_key_required = false

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = [
    aws_api_gateway_rest_api.lambda_api_gateway_rest_api,
    aws_api_gateway_resource.lambda_api_gateway_resource
  ]
}

resource "aws_api_gateway_method_response" "lambda_api_gateway_method_response" {
  count = var.lambda_function_enable && var.lambda_function_api_gateway ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.lambda_api_gateway_rest_api[0].id
  resource_id = aws_api_gateway_resource.lambda_api_gateway_resource[0].id
  http_method = aws_api_gateway_method.lambda_api_gateway_method[0].http_method
  status_code = "200"

  response_models = {
    "application/json": "Empty"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = [
    aws_api_gateway_rest_api.lambda_api_gateway_rest_api,
    aws_api_gateway_resource.lambda_api_gateway_resource,
    aws_api_gateway_method.lambda_api_gateway_method
  ]
}

resource "aws_api_gateway_integration" "lambda_api_gateway_integration" {
  count = var.lambda_function_enable && var.lambda_function_api_gateway ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.lambda_api_gateway_rest_api[0].id
  resource_id = aws_api_gateway_resource.lambda_api_gateway_resource[0].id
  http_method = aws_api_gateway_method.lambda_api_gateway_method[0].http_method
  type        = "AWS"

  integration_http_method = "POST"
  uri                     = aws_lambda_function.lambda_function[0].invoke_arn
  passthrough_behavior    = "WHEN_NO_MATCH"

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = [
    aws_api_gateway_rest_api.lambda_api_gateway_rest_api,
    aws_api_gateway_resource.lambda_api_gateway_resource,
    aws_api_gateway_method.lambda_api_gateway_method
  ]
}


resource "aws_api_gateway_integration_response" "lambda_api_gateway_integration_response" {
  count = var.lambda_function_enable && var.lambda_function_api_gateway ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.lambda_api_gateway_rest_api[0].id
  resource_id = aws_api_gateway_resource.lambda_api_gateway_resource[0].id
  http_method = aws_api_gateway_method.lambda_api_gateway_method[0].http_method
  status_code = aws_api_gateway_method_response.lambda_api_gateway_method_response[0].status_code

  response_templates = {
    "application/json" = "Empty"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = [
    aws_api_gateway_rest_api.lambda_api_gateway_rest_api,
    aws_api_gateway_resource.lambda_api_gateway_resource,
    aws_api_gateway_integration.lambda_api_gateway_integration,
    aws_api_gateway_method.lambda_api_gateway_method,
    aws_api_gateway_method_response.lambda_api_gateway_method_response
  ]
}


resource "aws_api_gateway_deployment" "lambda_api_gateway_deployment" {
  count = var.lambda_function_enable && var.lambda_function_api_gateway ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.lambda_api_gateway_rest_api[0].id
  stage_name  = var.environment

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = [
    aws_api_gateway_rest_api.lambda_api_gateway_rest_api,
    aws_api_gateway_integration_response.lambda_api_gateway_integration_response
  ]
}