terraform {
  required_version = "~> 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "nhs-england-tools-terraform-state-store"
    key            = "terraform-aws-opennext/example.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "nhs-england-tools-terraform-state-lock"
  }
}

locals {
  domain_name = "terraform-aws-opennext.tools.engineering.england.nhs.uk"
  default_tags = {
    Project     = "terraform-aws-opennext"
    Environment = "example"
  }
}

provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "global"
  region = "us-east-1"

  default_tags {
    tags = local.default_tags
  }
}

module "opennext" {
  source = "../../"

  prefix              = "terraform-aws-opennext-example"
  default_tags        = local.default_tags
  opennext_build_path = "../.open-next"
  hosted_zone_id      = data.aws_route53_zone.zone.zone_id

  cloudfront = {
    aliases             = [local.domain_name]
    acm_certificate_arn = aws_acm_certificate_validation.ssl_certificate.certificate_arn
    assets_paths        = ["/images/*"]
  }
}

output "cloudfront_distribution_id" {
  value = module.opennext.cloudfront.cloudfront_distribution.id
}
