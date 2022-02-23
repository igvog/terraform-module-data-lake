# Terraform module for AWS Data-Lake CI/CD

Terraform module developed for automation Data Lake AWS services deploy. Data engineers and DevOps/DataOps engineers can easily deploy data workflow CI/CD. Using this module with Terragrunt will help simplify processes.

## Module Input Variables

### AWS Glue Job

- `glue_job_enable` (Optional) - Enable glue job usage (`default` = false)
- `glue_job_s3_bucket` (**Reqired**) - S3 Bucket where Glue Job scripts will be uploaded (`default` = null)
- `role_arn` (**Required**) - The ARN of the IAM role associated with this job.
- `command` (Optional) - The command of the job. (default =
```
    command = [
        {
	    name = "glueetl",
            script_location = "s3://project-glue-scripts/env-project-name.py",
            python_version = "3"
        }
    ]
```
)
- `description` (Optional) - Description of the job. (`default` = null)
- `connections` (Optional) - The list of connections used for the job. (`default` = [])
- `default_arguments` (Optional) - The map of default arguments for this job. You can specify arguments here that your own job-execution script consumes, as well as arguments that AWS Glue itself consumes. For information about how to specify and consume your own Job arguments, see the Calling AWS Glue APIs in Python topic in the developer guide. For information about the key-value pairs that AWS Glue consumes to set up your job, see the Special Parameters Used by AWS Glue topic in the developer guide.
- `glue_version` (Optional) - The version of glue to use, for example '1.0'. For information about available versions, see the AWS Glue Release Notes. (`default` - "1.0")
- `max_capacity` (Optional) - The maximum number of AWS Glue data processing units (DPUs) that can be allocated when this job runs. Required when pythonshell is set, accept either 0.0625 or 1.0. 
- `max_retries` (Optional) - The maximum number of times to retry this job if it fails. (`default` = null)
- `timeout` (Optional) - The job timeout in minutes. The default is 2880 minutes (48 hours). (`default` = 2880)
- `security_configuration` (Optional) - The name of the Security Configuration to be associated with the job. (`default` = null)
- `worker_type` (Optional) - The type of predefined worker that is allocated when a job runs. Accepts a value of Standard, G.1X, or G.2X. (`default` = null)
- `number_of_workers` (Optional) - The number of workers of a defined workerType that are allocated when a job runs. (`default` = null)

### Example

```
glue_job_s3_bucket = "YOUR_BUCKET"
glue_job_enable = true
glue_job = {
    version = "2.0"
    timeout = 60
    worker_type = "Standard"
    number_of_workers = 2
    max_retries = 2
    role_arn = "arn:aws:iam::xxxxxxxxxx:role/xxxxxxx"
    execution_property = [
        {
            max_concurrent_runs = 1
        }
    ]
}
```


### AWS Glue Job Trigger

- `glue_job_trigger_enable` (Optional) - Enable glue job trigger usage `(default` = false)
- `type` - (****Required****) The type of trigger. Valid values are CONDITIONAL, ON_DEMAND, and SCHEDULED. (`default = ON_DEMAND`)
- `description` - (Optional) A description of the new trigger. (`default = null`)
- `enabled` - (Optional) Start the trigger. Defaults to true. Not valid to disable for ON_DEMAND type. (`default = null`)
- `schedule` - (Optional) A cron expression used to specify the schedule. Time-Based Schedules for Jobs and Crawlers (`default = null`)
- `workflow_name` - (Optional) A workflow to which the trigger should be associated to. Every workflow graph (DAG) needs a starting trigger (ON_DEMAND or SCHEDULED type) and can contain multiple additional CONDITIONAL triggers. (`default = null`)
- `actions` - (Optional) List of actions initiated by this trigger when it fires.  (`default = []`)
- `timeouts` - Set timeouts for glue trigger (`default = {}`)
- `predicate` - (Optional) A predicate to specify when the new trigger should fire. **Required** when trigger type is CONDITIONAL (`default = {}`)

### Example

```
glue_job_trigger_enable = true
glue_job_trigger = {
    type = "scheduled"
    schedule = "cron(* * * * ? *)"
}
```


## AWS Glue Crawler

- `glue_crawler_enable` - Enable glue crawler usage (`default = False`)
- `name` - Name of the crawler. (`default = ""`)
- `database_name` - Glue database where results are written. (`default = ""`)
- `role` - (**Required**) The IAM role friendly name (including path without leading slash), or ARN of an IAM role, used by the crawler to access other resources. (`default = ""`)
- `description` - (Optional) Description of the crawler. (`default = null`)
- `classifiers` - (Optional) List of custom classifiers. By default, all AWS classifiers are included in a crawl, but these custom classifiers always override the default classifiers for a given classification. (`default = null`)
- `configuration` - (Optional) JSON string of configuration information. (`default = null`)
- `schedule` - (Optional) A cron expression used to specify the schedule. For more information, see Time-Based Schedules for Jobs and Crawlers. For example, to run something every day at 12:15 UTC, you would specify: cron(15 12 * * ? *). (`default = null`)
- `security_configuration` - (Optional) The name of Security Configuration to be used by the crawler (`default = null`)
- `table_prefix` - (Optional) The table prefix used for catalog tables that are created. (`default = null`)
- `dynamodb_target` - (Optional) List of nested DynamoDB target arguments. (`default = []`)
- `jdbc_target` - (Optional) List of nested JBDC target arguments.  (`default = []`)
- `s3_target` - (Optional) List nested Amazon S3 target arguments. (`default = []`)
- `catalog_target` - (Optional) List nested Amazon catalog target arguments. (`default = []`)
- `schema_change_policy` - (Optional) Policy for the crawler's update and deletion behavior. (`default = []`)
- `recrawl_policy` - (Optional) A policy that specifies whether to crawl the entire dataset again, or to crawl only folders that were added since the last crawler run. (`default = []`)
- `mongodb_target` - (Optional) List nested MongoDB target arguments. (`default = []`)
- `lineage_configuration` - (Optional) Specifies data lineage configuration settings for the crawler. (`default = []`)

## Example

```
glue_crawler_enable = false
glue_crawler = {
    database_name = "test"
    role = "arn:aws:iam::xxxxxx:role/xxxxx"
    s3_target = [
        {
            path = "s3://YOUR_BUCKET/FOLDER/"
        }
    ]
}
```


## AWS Lambda

  - `role` - (**Required**) IAM Role ARN for lambda
  - `handler` - (Optional) Lambda function handler (`default` - "lambda_function.lambda_handler")
  - `runtime` - (Optional) Lambda function runtime (`default` - "python3.9")
  - `s3_bucket` - (Optional) S3 Bucket for keeping lambda function archive (`default` - null)
  - `s3_key` - (Optional) S3 key for lambda function archive (`default` - null)
  - `s3_object_version - (Optional) S3 Bucket version of lambda zip (`default` - null)
  - `description - (Optional) Description for lambda function (`default` - null)
  - `layers - (Optional) List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function. (`default` - null)
  - `memory_size - (Optional) Lambda function memory size (`default` - 128)
  - `timeout - (Optional) Lambda function execution timeout (`default` - 2880)
  - `reserved_concurrent_executions - (Optional) Lambda function concurrency execution (`default` - 1000)
  - `publish - (Optional) Whether to publish creation/change as new Lambda Function Version. (`default` - false)
  - `kms_key_arn - (Optional) Amazon Resource Name (ARN) of the AWS Key Management Service (KMS) key that is used to encrypt environment variables. If this configuration is not provided when environment variables are in use, AWS Lambda uses a default service key. If this configuration is provided when environment variables are not in use, the AWS Lambda API does not save this configuration and Terraform will show a perpetual difference of adding the key. To fix the perpetual difference, remove this configuration. (`default` - null)
  - `source_code_hash -  Used to trigger updates. Must be set to a base64-encoded SHA256 hash of the package file specified with either filename or s3_key. The usual way to set this is filebase64sha256("file.zip") (Terraform 0.11.12 and later) or base64sha256(file("file.zip")) (Terraform 0.11.11 and earlier), where "file.zip" is the local filename of the lambda function source archive.

## Example

```
lambda_function_enable = true
lambda_function = {
    role = "arn:aws:iam::xxxxxxx:role/xxxxxx"
}
```

## Example with VPC

```
lambda_function_enable = true
lambda_function = {
    role = "arn:aws:iam::xxxxxxx:role/xxxxxx"
    vpc_config = [{
        subnet_ids = ["subnet-xxx", "subnet-xxx", "subnet-xxx"]
        security_group_ids = ["sg-xxxxxx"]
    }]
}
```


## AWS Lambda Integration with AWS API Gateway

- `lambda_function_api_gateway_enable` - (Optional) Enable api gateway usage and integration with lambda

## Example

```
lambda_function_api_gateway_enable = true

lambda_function_enable = true
lambda_function = {
    role = "arn:aws:iam::xxxxxxx:role/xxxxxx"
}
```


## AWS Lambda Integration with CloudWatch Event Rule

- `lambda_function_event_rule_enable` - (Optional) Enable event rule usage and integration with lambda
- `schedule_expression` - (**Required**)

## Example

```
lambda_function_event_rule_enable = true
lambda_function_event_rule = {
    schedule_expression = "rate(5 minutes)" // or you can use "cron(* * * * ? *)"
}

lambda_function_enable = true
lambda_function = {
    role = "arn:aws:iam::xxxxxxx:role/xxxxxx"
}
```


## Authors

Okassov Marat (marat@qcloudy.io)
