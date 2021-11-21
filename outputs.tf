
output "test_size" {
    value = data.archive_file.lambda_function_zip[0].output_size/1024/1024
}
