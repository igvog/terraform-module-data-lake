locals {

    full_name = "${lower(var.environment)}-${lower(var.project)}-${lower(var.name)}"

    lambda_function_zip_size = var.lambda_function_enable ? (data.archive_file.lambda_function_zip[0].output_size / 1024 / 1024) : null

    base_tags = {
        Managed_By = "terraform"
        Env        = var.environment
        Project    = var.project
        Name       = local.full_name
    }
}
