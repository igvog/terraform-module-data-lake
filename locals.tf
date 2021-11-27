locals {

    full_name = "${lower(var.environment)}-${lower(var.project)}-${lower(var.name)}"

    lambda_function_zip_size = var.lambda_function_enable ? (data.archive_file.lambda_function_zip[0].output_size / 1024 / 1024) : null
    lambda_function_api_gateway_invoke_url = var.lambda_function_enable && var.lambda_function_api_gateway_enable ? "${aws_api_gateway_deployment.lambda_api_gateway_deployment[0].invoke_url}/${var.name}" : null

    base_tags = {
        Managed_By = "terraform"
        Env        = var.environment
        Project    = var.project
        Name       = local.full_name
    }
}
