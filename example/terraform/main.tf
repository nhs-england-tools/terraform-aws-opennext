terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  alias  = "global"
  region = "us-east-1"
}

data "aws_route53_zone" "zone" {
  name         = local.domain_name
  private_zone = false
}

locals {
  domain_name = "opennext-example.tomjc.dev"
}

module "opennext" {
  source = "../../"

  prefix              = "opennext-example"
  aliases             = [local.domain_name]
  acm_certificate_arn = aws_acm_certificate_validation.ssl_certificate.certificate_arn
  hosted_zone_id      = data.aws_route53_zone.zone.zone_id
  opennext_build_path = "../.open-next"
  assets_paths        = ["/images/*"]
}