data "archive_file" "lambda_function_zip" {
  count = var.lambda_function_enable ? 1 : 0

  type             = "zip"
  source_dir       = "${path.module}/../../lambda"
  output_file_mode = "0666"
  output_path      = "${path.module}/files/${local.full_name}.zip"
}

resource "aws_s3_bucket_object" "file_upload" {
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

  tags = {
    Managed_By = "terraform"
    Env        = var.environment
    Project    = var.project
    App        = "lambda"
    Name       = local.full_name
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = [
    data.archive_file.lambda_function_zip, 
    aws_s3_bucket_object.file_upload
  ]
}