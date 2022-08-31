#---------------------------------------------------
# AWS Glue job
#---------------------------------------------------

variable "region" {
  description = "AWS Region"
  type = string
  default = "us-east-1"
}

variable "environment" {
  description = "Environment"
}

variable "project" {
  description = "Global Project name"
}

variable "name" {
  description = "Project name"
}

variable "tags" {
  description = "A list of tag blocks. Each element should have keys named key, value, etc."
  type        = map(string)
  default     = {}
}


variable "glue_job_enable" {
  description = "Enable Glue job creation"
  type        = bool
  default     = false
}

variable "glue_job_s3_bucket" {
  description = "S3 bucket name for glue job scripts"
}

variable "glue_job" {
  description = "Glue job"
  type = object({
    role_arn               = string
    command                = optional(list(map(string)))
    description            = optional(string)
    version                = optional(string)
    timeout                = optional(number)
    worker_type            = optional(string)
    number_of_workers      = optional(number)
    max_capacity           = optional(number)
    max_retries            = optional(number)
    additional_libs        = optional(list(string))
    connections            = optional(list(string))
    execution_property     = optional(list(map(string)))
    notification_property  = optional(list(map(string)))
    security_configuration = optional(string)
    default_arguments      = optional(map(string))
    schedule               = optional(list(string))
    extra_jars             = optional(string)
    extra_py_files         = optional(string)
  })
}


variable "glue_job_trigger_enable" {
  description = "Enable Glue job trigger creation"
  type        = bool
  default     = false
}

variable "glue_job_trigger" {
    description = ""
    type = object({
        type = string
        actions = optional(list(any))
        enabled = optional(bool)
        description = optional(string)
        schedule = optional(string)
        workflow_name = optional(string)
        predicate = optional(list(map(string)))
        timeouts =  optional(list(map(string)))
    })
    default = null
}



variable "glue_crawler_enable" {
  description = "Enable Glue crawler creation"
  type        = bool
  default     = false
}

variable "glue_crawler" {
    description = ""
    type = object({
        database_name = string
        role = string
        description = optional(string)
        classifiers = optional(list(any))
        configuration = optional(string)
        schedule = optional(string)
        security_configuration = optional(string)
        table_prefix = optional(string)
        dynamodb_target = optional(list(any))
        jdbc_target = optional(list(map(string)))
        s3_target = optional(list(any))
        catalog_target = optional(map(string))
        schema_change_policy = optional(list(any))
        mongodb_target = optional(list(any))
        lineage_configuration = optional(list(any))
        recrawl_policy = optional(list(any))
    })
}

variable "lambda_function_enable" {
  description = "Enable Lambda function creation"
  type        = bool
  default     = false
}

variable "lambda_function_api_gateway_enable" {
  description = "Enable lambda integration with API Gateway (Method - POST)"
  type = bool
  default = false
}

variable "lambda_function_event_rule_enable" {
  description = "Enable lambda integration with CloudWatch Event Rule for schedulled execution"
  type = bool
  default = false
}

variable "lambda_function_event_rule" {
  description = "Enable lambda integration with CloudWatch Event Rule for schedulled execution"
  type = object({
    schedule_expression = string
  })
}

variable "lambda_function" {
    description = ""
    type = object({
        role = string
        handler = optional(string)
        runtime = optional(string)
        filename = optional(string)
        s3_bucket = optional(string)
        s3_key = optional(string)
        s3_object_version = optional(string)
        description = optional(string)
        layers = optional(list(any))
        memory_size = optional(number)
        timeout = optional(number)
        reserved_concurrent_executions = optional(number)
        publish = optional(bool)
        kms_key_arn = optional(string)
        source_code_hash = optional(string)
        dead_letter_config = optional(list(any))
        tracing_config = optional(list(any))
        vpc_config = optional(list(any))
        environment = optional(map(any))
        timeouts = optional(list(any))
    })
}
