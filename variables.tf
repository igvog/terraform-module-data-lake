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
    type = bool
}

variable "glue_job" {
    description = "Glue job"
    type = object({
        description = string
        version = optional(string)
        timeout = optional(number)
        command = list(map(string))
        worker_type = optional(string)
        number_of_workers = optional(number)
        max_capacity = optional(number)
        max_retries = optional(number)
        role_arn = string
        additional_libs = optional(list(string))
        connections = optional(list(string))
        execution_property = optional(list(map(string)))
        notification_property = optional(list(map(string)))
        security_configuration = optional(string)
        default_arguments = optional(map(string))
        schedule = optional(list(string))
    })
}