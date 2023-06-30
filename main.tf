terraform {
  required_version = "~> 1.5"

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

locals {
  opennext_abs_path = "${abspath(path.root)}/${var.opennext_build_path}"
}

data "aws_caller_identity" "current" {}

module "server_function" {
  source = "./modules/opennext-lambda"

  prefix      = "${var.prefix}-nextjs-server"
  description = "Next.js Server"
  publish     = true
  source_dir  = "${local.opennext_abs_path}/server-function/"

  environment_variables = {
    CACHE_BUCKET_NAME         = module.assets.assets_bucket.bucket
    CACHE_BUCKET_KEY_PREFIX   = "cache"
    CACHE_BUCKET_REGION       = "eu-west-2"
    REVALIDATION_QUEUE_URL    = module.revalidation_queue.queue.url
    REVALIDATION_QUEUE_REGION = "eu-west-2"
  }

  iam_policy_statements = [
    {
      effect    = "Allow"
      actions   = ["s3:GetObject", "s3:PutObject", "s3:ListObjects"]
      resources = [module.assets.assets_bucket.arn, "${module.assets.assets_bucket.arn}/*"]
    },
    {
      effect    = "Allow"
      actions   = ["sqs:SendMessage"]
      resources = [module.revalidation_queue.queue.arn]
    }
  ]
}

module "image_optimization_function" {
  source = "./modules/opennext-lambda"

  prefix      = "${var.prefix}-nextjs-image-optimization"
  description = "Next.js Image Optimization"
  memory_size = 512
  source_dir  = "${local.opennext_abs_path}/image-optimization-function/"

  environment_variables = {
    BUCKET_NAME       = module.assets.assets_bucket.bucket,
    BUCKET_KEY_PREFIX = "assets"
  }

  iam_policy_statements = [{
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = [module.assets.assets_bucket.arn, "${module.assets.assets_bucket.arn}/*"]
  }]
}

module "revalidation_function" {
  source = "./modules/opennext-lambda"

  prefix      = "${var.prefix}-nextjs-revalidation-function"
  description = "Next.js ISR Revalidation Function"
  source_dir  = "${local.opennext_abs_path}/image-optimization-function/"

  memory_size = 128

  iam_policy_statements = [
    {
      effect    = "Allow"
      actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
      resources = [module.revalidation_queue.queue.arn]
    }
  ]
}

module "warmer_function" {
  source = "./modules/opennext-lambda"

  create_eventbridge_scheduled_rule = true
  prefix                            = "${var.prefix}-nextjs-warmer"
  description                       = "Next.js Warmer"
  memory_size                       = 128
  source_dir                        = "${local.opennext_abs_path}/warmer-function/"

  environment_variables = {
    FUNCTION_NAME = module.server_function.lambda_function.function_name,
    CONCURRENCY   = 1
  }

  iam_policy_statements = [{
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [module.server_function.lambda_function.arn]
  }]
}

module "assets" {
  source = "./modules/opennext-assets"

  aws_account_id           = data.aws_caller_identity.current.account_id
  prefix                   = "${var.prefix}-assets"
  assets_path              = "${local.opennext_abs_path}/assets"
  cache_path               = "${local.opennext_abs_path}/cache"
  server_function_role_arn = module.server_function.lambda_role.arn
}


module "cloudfront_logs" {
  source = "./modules/cloudfront-logs"

  log_group_name  = "${var.prefix}-cloudfront-logs"
  log_bucket_name = "${var.prefix}-cloudfront-logs"
  retention       = 365
}

module "cloudfront" {
  source = "./modules/opennext-cloudfront"
  prefix = "${var.prefix}-cloudfront"

  aliases                       = var.aliases
  logging_bucket_domain_name    = module.cloudfront_logs.logs_s3_bucket.bucket_regional_domain_name
  assets_origin_access_identity = module.assets.cloudfront_origin_access_identity.cloudfront_access_identity_path
  acm_certificate_arn           = var.acm_certificate_arn
  origins = {
    assets_bucket               = module.assets.assets_bucket.bucket_regional_domain_name
    server_function             = "${module.server_function.lambda_function_url.url_id}.lambda-url.eu-west-2.on.aws"
    image_optimization_function = "${module.image_optimization_function.lambda_function_url.url_id}.lambda-url.eu-west-2.on.aws"
  }
}

module "revalidation_queue" {
  source = "./modules/opennext-revalidation-queue"
  prefix = "${var.prefix}-revalidation-queue"

  aws_account_id            = data.aws_caller_identity.current.account_id
  revalidation_function_arn = module.revalidation_function.lambda_function.arn
}
