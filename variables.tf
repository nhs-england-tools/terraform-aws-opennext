variable "prefix" {
  type        = string
  description = "Prefix for created resource IDs"
  default     = "opennext"
}

variable "acm_certificate_arn" {
  type        = string
  description = "The ACM (SSL) certificate ARN for the domain name"
}

variable "hosted_zone_id" {
  type        = string
  description = "The Route 53 hosted zone ID of the domain name"
}

variable "opennext_build_path" {
  type        = string
  description = "The path to the folder containing the .open-next build output"
}

variable "kms_key_arn" {
  type        = string
  default     = null
  description = "The KMS key to use for encrypting the Lambda functions"
}

variable "assets_paths" {
  type        = list(string)
  default     = []
  description = "Paths to expose as static assets (i.e. /images/*)"
}

# Route53 (DNS) Variables
variable "create_route53_records" {
  type        = bool
  default     = true
  description = "Create Route53 DNS Records for CloudFront distribution"
}

variable "evaluate_target_health" {
  type        = bool
  default     = false
  description = "Allow Route53 to determine whether to respond to DNS queries by checking the health of the record set"
}

# CloudFront Variables
variable "aliases" {
  type        = list(string)
  description = "The aliases (domain names) to be used for the Next.js application"
}

variable "custom_headers" {
  type = list(object({
    header   = string
    override = bool
    value    = string
  }))
  description = "Add custom headers to the CloudFront response headers policy"
  default     = []
}

variable "cors" {
  description = "CORS (Cross-Origin Resource Sharing) configuration for the CloudFront distribution"
  type = object({
    allow_credentials = bool,
    allow_headers     = list(string),
    allow_methods     = list(string),
    allow_origins     = list(string)
    origin_override   = bool
  })
  default = {
    allow_credentials = false,
    allow_headers     = ["*"],
    allow_methods     = ["ALL"],
    allow_origins     = ["*"],
    origin_override   = true
  }
}

# S3 Configuration
variable "static_assets_kms_key_arn" {
  description = "The KMS Key ARN for the encryption of the static assets S3 bucket"
  type        = string
  default     = "aws/s3"
}

variable "revalidation_queue_kms_key_arn" {
  description = "The KMS Key ARN for the encryption of the invalidation SQS queue"
  type        = string
  default     = "aws/sqs"
}