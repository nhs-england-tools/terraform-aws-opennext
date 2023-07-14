variable "prefix" {
  type        = string
  description = "Prefix for created resource IDs"
}

variable "default_tags" {
  type        = map(string)
  description = "Default tags to apply to all created resources"
  default     = {}
}

variable "aws_account_id" {
  type        = string
  description = "The account ID of the current AWS account"
}

variable "kms_key_arn" {
  type        = string
  description = "The ARN of the KMS key used to encrypt the SQS queue"
  default     = null
}

variable "revalidation_function_arn" {
  type        = string
  description = "The ARN of the revalidation lambda function"
}
