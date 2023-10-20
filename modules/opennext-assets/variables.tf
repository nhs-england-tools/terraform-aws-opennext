variable "prefix" {
  type        = string
  description = "Prefix for created resource IDs"
}

variable "default_tags" {
  type        = map(string)
  description = "Default tags to apply to all created resources"
  default     = {}
}



variable "assets_path" {
  type        = string
  description = "The path of the open-next static assets"
}

variable "cache_path" {
  type        = string
  description = "The path of the open-next cache"
}

variable "server_function_role_arn" {
  type        = string
  description = "The IAM role ARN of the Next.js server lambda function"
}

variable "logging_config" {
  type = object({
    target_bucket = string
    target_prefix = string
  })
  default = null
}

variable "replication_configuration" {
  description = "Replication Configuration for the S3 bucket"
  default     = null
  type = object({
    role = string
    rules = list(object({
      id     = string
      status = string
      filters = list(object({
        prefix = string
      }))
      destination = object({
        bucket        = string
        storage_class = string
      })
    }))
  })
}
