data "archive_file" "lambda_function_zip" {
  count = var.lambda_function_enable ? 1 : 0

  type             = "zip"
  source_dir       = "${path.module}/../../../lambda"
  output_file_mode = "0666"
  output_path      = "${path.module}/files/${local.full_name}.zip"
}

resource "null_resource" "lambda_function_zip_upload" {
  count = var.lambda_function_enable ? 1 : 0
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "aws s3 cp ${path.module}/files/${local.full_name}.zip s3://${var.lambda_function.s3_bucket}/"
    }
}

resource "aws_lambda_function" "lambda_function" {
  count = var.lambda_function_enable ? 1 : 0

  function_name = local.full_name
  role          = var.lambda_function.role

  handler = var.lambda_function.handler != null ? var.lambda_function.handler : "lambda_function.lambda_handler"
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
    null_resource.lambda_function_zip_upload
  ]
}


// API Gateway integration
//
resource "aws_api_gateway_rest_api" "lambda_api_gateway_rest_api" {
  count = var.lambda_function_enable && var.lambda_function_api_gateway_enable ? 1 : 0

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

resource "aws_lambda_permission" "lambda_permission_api_gateway" {
  count = var.lambda_function_enable && var.lambda_function_api_gateway_enable ? 1 : 0

  action        = "lambda:InvokeFunction"
  function_name = local.full_name
  principal     = "apigateway.amazonaws.com"

  source_arn   = "${aws_api_gateway_rest_api.lambda_api_gateway_rest_api[0].execution_arn}/*/POST/${var.name}"
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

resource "aws_api_gateway_resource" "lambda_api_gateway_resource" {
  count = var.lambda_function_enable && var.lambda_function_api_gateway_enable ? 1 : 0

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
  count = var.lambda_function_enable && var.lambda_function_api_gateway_enable ? 1 : 0

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
  count = var.lambda_function_enable && var.lambda_function_api_gateway_enable ? 1 : 0

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
  count = var.lambda_function_enable && var.lambda_function_api_gateway_enable ? 1 : 0

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
  count = var.lambda_function_enable && var.lambda_function_api_gateway_enable ? 1 : 0

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
  count = var.lambda_function_enable && var.lambda_function_api_gateway_enable ? 1 : 0

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

// CloudWatch Event Bridge Integration
//
resource "aws_cloudwatch_event_rule" "lambda_cw_event_rule" {
  count = var.lambda_function_enable && var.lambda_function_event_rule_enable ? 1 : 0

  name        = local.full_name
  description = "Event Rule for trigger lambda: ${local.full_name}"
  is_enabled  = true

  schedule_expression = var.lambda_function_event_rule.schedule_expression

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

resource "aws_cloudwatch_event_target" "lambda_cw_event_target" {
  count = var.lambda_function_enable && var.lambda_function_event_rule_enable ? 1 : 0

  rule      = aws_cloudwatch_event_rule.lambda_cw_event_rule[0].id
  target_id = local.full_name
  arn       = aws_lambda_function.lambda_function[0].arn

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = [aws_cloudwatch_event_rule.lambda_cw_event_rule]
}

resource "aws_lambda_permission" "lambda_permission_event_rule" {
  count = var.lambda_function_enable && var.lambda_function_event_rule_enable  ? 1 : 0

  action        = "lambda:InvokeFunction"
  function_name = local.full_name
  principal     = "events.amazonaws.com"

  source_arn   = aws_cloudwatch_event_rule.lambda_cw_event_rule[0].arn
  statement_id = "AllowEventRuleInvoke"

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = [
    aws_lambda_function.lambda_function,
    aws_cloudwatch_event_rule.lambda_cw_event_rule,
  ]
}

resource "aws_lambda_function_url" "lambda_function_uri" {
  count = var.lambda_function_enable && var.lambda_function_url_enable ? 1 : 0

  function_name = local.full_name

  # Error: error creating Lambda Function URL: ValidationException
  qualifier          = var.create_unqualified_alias_lambda_function_url ? null : aws_lambda_function.lambda_function[0].version
  authorization_type = var.authorization_type

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
  #dynamic "cors" {
  #  for_each = length(keys(var.cors)) == 0 ? [] : [var.cors]
  #
  #  content {
  #    allow_credentials = try(cors.value.allow_credentials, null)
  #    allow_headers     = try(cors.value.allow_headers, null)
  #    allow_methods     = try(cors.value.allow_methods, null)
  #    allow_origins     = try(cors.value.allow_origins, null)
  #    expose_headers    = try(cors.value.expose_headers, null)
  #    max_age           = try(cors.value.max_age, null)
  #  }
  #}
}

##################
# Adding S3 bucket as trigger to my lambda and giving the permissions
##################
resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  count = var.lambda_function_enable && var.lambda_function_s3_trigger_enable ? 1 : 0
  bucket = var.lambda_function.s3_bucket #"${aws_s3_bucket.bucket.id}"
  lambda_function {
  lambda_function_arn = "arn:aws:lambda:eu-north-1:313555887466:function:prod-technodom-test-env" #aws_lambda_function.lambda_function.arn
  events              = ["s3:ObjectCreated:*"]
  filter_prefix       = "file-prefix"
  filter_suffix       = "file-extension"
  }
}
resource "aws_lambda_permission" "test" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = local.full_name #"${aws_lambda_function.test_lambda.function_name}"
  principal = "s3.amazonaws.com"
  source_arn = "arn:aws:s3:::${var.lambda_function.s3_bucket}"
}