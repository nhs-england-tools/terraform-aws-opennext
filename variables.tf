variable "prefix" {
  type        = string
  description = "Prefix for created resource IDs"
  default     = "opennext"
}

variable "domain_name" {
  type        = string
  description = "The domain name for the Next.js application"
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