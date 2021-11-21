# Terraform module for AWS Data-Lake CI/CD

## Glue Job

```
glue_job_bucket = "aws-glue-scripts"
glue_job_enable = true
glue_job = {
    description = "test job"
    version = "2.0"
    timeout = 60
    command = [
        {
	        name = "glueetl",
            script_location = "s3://aws-glue-scripts/test.py",
            python_version = "3"
        }
    ]
    worker_type = "Standard"
    number_of_workers = 2
    max_retries = 2
    role_arn = "arn:aws:iam::xxxxxxxxxx:role/xxxxxxx"
    execution_property = [
        {
            max_concurrent_runs = 1
        }
    ]
    notification_property = [
        {
            notify_delay_after = 1
        }
    ]
}
```