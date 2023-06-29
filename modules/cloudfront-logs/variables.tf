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

variable "lambda_runtime" {
  type    = string
  default = "nodejs18.x"
}

variable "release_version" {
  type = string
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