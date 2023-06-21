locals {
  domain_name = "opennext-example.tomjc.dev"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
    alias = "global"
    region = "us-east-1"
}

data "aws_route53_zone" "zone" {
  name         = local.domain_name
  private_zone = false
}


resource "aws_acm_certificate" "ssl_certificate" {
    provider = aws.global
  domain_name       = local.domain_name
  validation_method = "DNS"
}

resource "aws_route53_record" "ssl_certificate_validation" {
  for_each = {
    for dvo in aws_acm_certificate.ssl_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
}

resource "aws_acm_certificate_validation" "ssl_certificate" {
    provider = aws.global
  certificate_arn         = aws_acm_certificate.ssl_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.ssl_certificate_validation : record.fqdn]
}

module "opennext" {
  source  = "../../"

  prefix      = "opennext-example"
  domain_name = local.domain_name
  acm_certificate_arn = aws_acm_certificate_validation.ssl_certificate.certificate_arn
  hosted_zone_id = data.aws_route53_zone.zone.zone_id
  opennext_build_path = "../.open-next"
}