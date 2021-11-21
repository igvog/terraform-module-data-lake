data "archive_file" "lambda_function_zip" {
  count = var.lambda_function_enable ? 1 : 0

  type             = "zip"
  source_dir      = "${path.module}/../lambda"
  output_file_mode = "0666"
  output_path      = var.lambda_function.filename != null ? "${path.module}/files/${var.lambda_function.filename}" : "${path.module}/files/${lower(var.environment)}-${lower(var.project)}-${lower(var.name)}.zip"
}

resource "aws_s3_bucket_object" "file_upload" {
  count = var.lambda_function_enable && (
      var.lambda_function.s3_bucket != null || 
      (data.archive_file.lambda_function_zip[0].output_size/1024/1024) > 50
      ) ? 1 : 0

  bucket = var.lambda_function.s3_bucket == null && (data.archive_file.lambda_function_zip[0].output_size/1024/1024) > 50 ? "lambda-mara" : null
  key    = var.lambda_function.s3_key == null && (data.archive_file.lambda_function_zip[0].output_size/1024/1024) > 50 ? "${lower(var.environment)}-${lower(var.project)}-${lower(var.name)}.zip" : null
  source = var.lambda_function.filename != null ? "${path.module}/files/${var.lambda_function.filename}" : "${path.module}/files/${lower(var.environment)}-${lower(var.project)}-${lower(var.name)}.zip"
  etag   = var.lambda_function.filename != null ? "${filemd5("${path.module}/files/${var.lambda_function.filename}")}" : "${filemd5("${path.module}/files/${lower(var.environment)}-${lower(var.project)}-${lower(var.name)}.zip")}"
}

resource "aws_lambda_function" "lambda_function" {
  count = var.lambda_function_enable ? 1 : 0

  function_name = "${lower(var.environment)}-${lower(var.project)}-${lower(var.name)}"
  role          = var.lambda_function.role

  handler       = var.lambda_function.handler != null ? var.lambda_function.handler : "lambda_handler"
  runtime       = var.lambda_function.runtime != null ? var.lambda_function.runtime : "python3.6"

  filename                       = var.lambda_function.filename != null ? "${path.module}/files/${var.lambda_function.filename}" : "${path.module}/files/${lower(var.environment)}-${lower(var.project)}-${lower(var.name)}.zip"
  s3_bucket                      = var.lambda_function.s3_bucket == null && (data.archive_file.lambda_function_zip[0].output_size/1024/1024) > 50 ? "lambda-mara" : null
  s3_key                         = var.lambda_function.s3_key == null && (data.archive_file.lambda_function_zip[0].output_size/1024/1024) > 50 ? "${lower(var.environment)}-${lower(var.project)}-${lower(var.name)}.zip" : null
  s3_object_version              = var.lambda_function.s3_object_version
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
    App        = "glue"
    Name       = "${lower(var.environment)}-${lower(var.project)}-${lower(var.name)}"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = [data.archive_file.lambda_function_zip]
}