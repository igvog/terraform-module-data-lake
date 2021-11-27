locals {

    full_name = "${lower(var.environment)}-${lower(var.project)}-${lower(var.name)}"

    lambda_function_zip_size = data.archive_file.lambda_function_zip[0].output_size / 1024 / 1024

    base_tags = {
        Managed_By = "terraform"
        Env        = var.environment
        Project    = var.project
        Name       = local.full_name
    }
}
