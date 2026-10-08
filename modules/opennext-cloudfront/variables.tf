variable "prefix" {
  type        = string
  description = "Prefix for created resource IDs"
}

variable "default_tags" {
  type        = map(string)
  description = "Default tags to apply to all created resources"
  default     = {}
}

variable "region" {
  type        = string
  description = "The deployment region to be used by the AWS provider."
}

variable "comment" {
  type        = string
  description = "Comment to add to the CloudFront distribution"
}

variable "acm_certificate_arn" {
  type = string
}

variable "price_class" {
  type        = string
  description = "The price class to use for the distribution"
  validation {
    condition     = contains(["PriceClass_200", "PriceClass_100", "PriceClass_All"], var.price_class)
    error_message = "Valid values for price_class are: `PriceClass_200`, `PriceClass_100` and `PriceClass_All`."
  }
  default = "PriceClass_All"
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
  default     = []
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

variable "custom_waf" {
  description = "ARN value for an externally created AWS WAF"
  type = object({
    arn = string
  })
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

variable "origin_request_policy" {
  type = object({
    cookies_config = object({
      cookie_behavior = string
      items           = list(string)
    })
    headers_config = object({
      header_behavior = string
      items           = optional(list(string))
    })
    query_strings_config = object({
      query_string_behavior = string
      items                 = optional(list(string))
    })
  })
  default = null
}

variable "cache_policy" {
  type = object({
    default_ttl                   = number
    min_ttl                       = number
    max_ttl                       = number
    enable_accept_encoding_gzip   = bool
    enable_accept_encoding_brotli = bool
    cookies_config = object({
      cookie_behavior = string
      items           = optional(list(string))
    })
    headers_config = object({
      header_behavior = string
      items           = optional(list(string))
    })
    query_strings_config = object({
      query_string_behavior = string
      items                 = optional(list(string))
    })
  })
}

variable "no_cache_paths" {
  type        = list(string)
  default     = []
  description = "List of path patterns that should have caching disabled"
}

variable "geo_restriction" {
  description = "The georestriction configuration for the CloudFront distribution"
  type = object({
    restriction_type = string
    locations        = list(string)
  })
}

variable "remove_headers_config" {
  description = "Response header removal configuration for the CloudFront distribution"
  type = object({
    items = list(string)
  })
}

