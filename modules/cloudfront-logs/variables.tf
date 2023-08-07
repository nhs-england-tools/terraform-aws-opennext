variable "default_tags" {
  type        = map(string)
  description = "Default tags to apply to all created resources"
  default     = {}
}


variable "log_group_name" {
  type = string
}

variable "retention" {
  type    = number
  default = 365
}

variable "log_bucket_name" {
  type = string
}

variable "log_bucket_kms_key_arn" {
  type    = string
  default = "aws/s3"
}

variable "log_bucket_logging_config" {
  type = object({
    target_bucket = string
    target_prefix = string
  })
  default = null
}

variable "log_bucket_replication_configuration" {
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


variable "lambda_runtime" {
  type    = string
  default = "nodejs18.x"
}

variable "lambda_log_retention_period" {
  type    = number
  default = 365
}

variable "kms_key_arn" {
  type        = string
  default     = null
  description = "The KMS key to use for encrypting the Lambda function"
}

variable "vpc_config" {
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "cloudwatch_log_group_kms_key_arn" {
  description = "The KMS key to use for encrypting the CloudWatch log group"
  type        = string
  default     = null
}

variable "code_signing_config" {
  description = "Code Signing Config for the Lambda Function"
  type = object({
    description                     = optional(string)
    signing_profile_version_arns    = list(string)
    untrusted_artfact_on_deployment = optional(string)
  })
  default = null
}

variable "dead_letter_config" {
  description = "Lambda Dead Letter Queue (DLQ) Configuration"
  default     = null
  type = object({
    target_arn = string
  })
}
