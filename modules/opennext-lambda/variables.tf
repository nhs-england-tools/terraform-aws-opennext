/**
 * Common Variables
 **/
variable "prefix" {
  type        = string
  description = "Prefix for created resource IDs"
}

variable "default_tags" {
  type        = map(string)
  description = "Default tags to apply to all created resources"
  default     = {}
}



/**
 * Create Toggles
 **/
variable "create_eventbridge_scheduled_rule" {
  type        = bool
  description = "Toggle to create an scheduled rule in eventbridge to invoke the lambda function"
  default     = false
}


/**
 * Lambda Package Variables
 **/
variable "source_dir" {
  type        = string
  description = "The directory to use as the lambda deployment package"
}

variable "output_dir" {
  type        = string
  description = "The directory to use to store the lambda deployment packages"
}


/**
 * Lambda Function Variables
 **/
variable "function_name" {
  type        = string
  description = "The name of the Lambda function. Defaults to var.prefix"
  default     = null
}

variable "description" {
  type        = string
  description = "A description of the Lambda function"
}

variable "handler" {
  type        = string
  description = "The handler path for the lambda function"
  default     = "index.handler"
}

variable "runtime" {
  type        = string
  description = "The Lambda runtime to use"
  default     = "nodejs18.x"
}

variable "architectures" {
  type        = list(string)
  description = "The architectures to use for the lambda function"
  default     = ["arm64"]
}

variable "memory_size" {
  type        = number
  description = "The memory (in MB) to allocate for the lambda function"
  default     = 1024
}

variable "timeout" {
  type        = number
  description = "The timeout period for the lambda function (in seconds)"
  default     = 30
}

variable "publish" {
  type        = bool
  description = "Publish the lambda function to Lambda@Edge"
  default     = false
}

variable "environment_variables" {
  type        = map(string)
  description = "The environment variables to be used for the lambda function"
  default     = {}
}

variable "kms_key_arn" {
  type        = string
  description = "The KMS key to use for encrypting the Lambda function"
  default     = null
}

variable "log_group" {
  description = "Options passed to the CloudWatch log group for the Lambda function"
  type = object({
    retention_in_days = number
    kms_key_id        = string
  })
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

variable "reserved_concurrent_executions" {
  description = "Concurrency limit for the lambda function"
  type        = number
  default     = 10
}


/**
 * Lambda Networking
 **/
variable "vpc_id" {
  type        = string
  description = "The VPC to attach the lambda function to"
  default     = null
}

variable "subnet_ids" {
  type        = list(string)
  description = "The subnets to attach the lambda function to (if vpc_id is provided)"
  default     = []
}

variable "security_group_ingress_rules" {
  type = list(object({
    description      = string
    from_port        = number
    to_port          = number
    cidr_blocks      = optional(list(string))
    ipv6_cidr_blocks = optional(list(string))
    prefix_list_ids  = optional(list(string))
    protocol         = optional(string)
    security_groups  = optional(list(string))
    self             = optional(bool)
  }))
  description = "Ingress rules to add to the lambda security group (if in VPC)"
  default     = []
}

variable "security_group_egress_rules" {
  type = list(object({
    description      = string
    from_port        = number
    to_port          = number
    cidr_blocks      = optional(list(string))
    ipv6_cidr_blocks = optional(list(string))
    prefix_list_ids  = optional(list(string))
    protocol         = optional(string)
    security_groups  = optional(list(string))
    self             = optional(bool)
  }))
  description = "Egress rules to add to the lambda security group (if in VPC)"
  default     = []
}

/**
 * Lambda IAM Policy
 **/
variable "iam_policy_statements" {
  type = list(object({
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  description = "IAM policy statements to attach to the lambda function role"
  default     = []
}

/**
 * EventBridge Scheduled Rule
 **/
variable "schedule_expression" {
  type        = string
  description = "The schedule expression of the eventbridge lambda trigger rule (if enabled)"
  default     = "rate(5 minutes)"
}
