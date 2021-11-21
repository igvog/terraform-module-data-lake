#---------------------------------------------------
# AWS Glue job
#---------------------------------------------------

variable "environment" {
  description = "Environment"
}

variable "project" {
  description = "Global Project name"
}

variable "name" {
  description = "Project name"
}

variable "glue_job_enable" {
  description = "Enable Glue job creation"
  type        = bool
}

variable "glue_job_bucket" {
  description = "S3 bucket name for glue job scripts"
}

variable "glue_job_bucket_folder" {
  description = "Folder in S3 bucket"
  default = null
}

variable "glue_job" {
  description = "Glue job"
  type = object({
    role_arn               = string
    command                = list(map(string))
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