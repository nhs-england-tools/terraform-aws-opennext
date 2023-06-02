variable "prefix" {
    type = string
    description = "Prefix for created resource IDs"
    default = "opennext"
}

variable "domain_name" {
    type = string
    description = "The domain name for the Next.js application"
}

variable "acm_certificate_arn" {
    type = string
    description = "The ACM (SSL) certificate ARN for the domain name"
}

variable "hosted_zone_id" {
    type = string
    description = "The Route 53 hosted zone ID of the domain name"
}
