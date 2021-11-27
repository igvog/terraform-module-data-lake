
output "lambda_size" {
    value = local.lambda_function_zip_size
}

output "api_gateway_invoke_url" {
    value = local.lambda_function_api_gateway_invoke_url
}
