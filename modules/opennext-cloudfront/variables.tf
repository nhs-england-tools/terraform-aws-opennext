variable "prefix" {
  type        = string
  description = "Prefix for created resource IDs"
}

variable "acm_certificate_arn" {
  type = string
}

variable "origins" {
  type = object({
    assets_bucket               = string
    server_function             = string
    image_optimization_function = string
  })
}

variable "assets_origin_access_identity" {
  type = string
}

variable "logging_bucket_domain_name" {
  type = string
}

variable "assets_paths" {
  type        = list(string)
  default     = []
  description = "Paths to expose as static assets (i.e. /images/*)"
}

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
    allow_headers     = list(string)
    allow_methods     = list(string)
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

variable "hsts" {
  description = "HSTS (HTTP Strict Transport Security) configuration for the CloudFront distribution"
  type = object({
    access_control_max_age_sec = number
    include_subdomains         = bool
    override                   = bool
    preload                    = bool
  })
  default = {
    access_control_max_age_sec = 31536000
    include_subdomains         = true
    override                   = true
    preload                    = true
  }
}

variable "waf_logging_configuration" {
  description = "Logging Configuration for the WAF attached to CloudFront"
  type = object({
    log_destination_configs = list(string)
    logging_filter = optional(object({
      default_behavior = string
      filter = list(object({
        behavior    = string
        requirement = string
        action_condition = optional(list(object({
          action = string
        })))
        label_name_condition = optional(list(object({
          label_name = string
        })))
      }))
    }))
    redacted_fields = optional(list(object({
      method       = optional(bool)
      query_string = optional(bool)
      single_header = optional(object({
        name = string
      }))
      uri_path = optional(bool)
    })))
  })

  default = null
}