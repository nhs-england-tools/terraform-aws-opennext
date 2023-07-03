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
data "aws_region" "current" {}

/**
 * Assets & Cache S3 Bucket
 **/
module "assets" {
  source = "./modules/opennext-assets"

  aws_account_id           = data.aws_caller_identity.current.account_id
  prefix                   = "${var.prefix}-assets"
  assets_path              = "${local.opennext_abs_path}/assets"
  cache_path               = "${local.opennext_abs_path}/cache"
  server_function_role_arn = module.server_function.lambda_role.arn
}


/**
 * Next.js Server Function
 **/
locals {
  server_options = {
    package = {
      source_dir = coalesce(try(var.server_options.package.source_dir, null), "${local.opennext_abs_path}/server-function/")
      output_dir = coalesce(try(var.server_options.package.output_dir, null), "/tmp/")
    }

    lambda = {
      function_name                  = try(var.server_options.lambda.function_name, null)
      description                    = coalesce(try(var.server_options.lambda.description, null), "Next.js Server")
      handler                        = coalesce(try(var.server_options.lambda.handler, null), "index.handler")
      runtime                        = coalesce(try(var.server_options.lambda.runtime, null), "nodejs18.x")
      architectures                  = coalesce(try(var.server_options.lambda.architectures, null), ["arm64"])
      memory_size                    = coalesce(try(var.server_options.lambda.memory_size, null), 1024)
      timeout                        = coalesce(try(var.server_options.lambda.timeout, null), 30)
      publish                        = coalesce(try(var.server_options.lambda.publish, null), true)
      dead_letter_config             = try(var.server_options.lambda.dead_letter_config, null)
      reserved_concurrent_executions = coalesce(try(var.server_options.lambda.reserved_concurrent_executions, null), 10)
      code_signing_config            = try(var.server_options.lambda.code_signing_config, null)
    }

    networking = {
      vpc_id                       = try(var.server_options.networking.vpc_id, null)
      subnet_ids                   = coalesce(try(var.server_options.networking.subnet_ids, null), [])
      security_group_ingress_rules = coalesce(try(var.server_options.networking.sg_ingress_rules, null), [])
      security_group_egress_rules  = coalesce(try(var.server_options.networking.sg_egress_rules, null), [])
    }

    environment_variables = merge({
      CACHE_BUCKET_NAME         = module.assets.assets_bucket.bucket
      CACHE_BUCKET_KEY_PREFIX   = "cache"
      CACHE_BUCKET_REGION       = data.aws_region.current.name
      REVALIDATION_QUEUE_URL    = module.revalidation_queue.queue.url
      REVALIDATION_QUEUE_REGION = data.aws_region.current.name
    }, coalesce(try(var.server_options.environment_variables, null), {}))

    iam_policy_statements = concat([
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
    ], coalesce(try(var.server_options.iam_policy, null), []))
  }
}

module "server_function" {
  source = "./modules/opennext-lambda"

  prefix = "${var.prefix}-nextjs-server"

  function_name                  = local.server_options.lambda.function_name
  description                    = local.server_options.lambda.description
  handler                        = local.server_options.lambda.handler
  runtime                        = local.server_options.lambda.runtime
  architectures                  = local.server_options.lambda.architectures
  memory_size                    = local.server_options.lambda.memory_size
  timeout                        = local.server_options.lambda.timeout
  publish                        = local.server_options.lambda.publish
  dead_letter_config             = local.server_options.lambda.dead_letter_config
  reserved_concurrent_executions = local.server_options.lambda.reserved_concurrent_executions
  code_signing_config            = local.server_options.lambda.code_signing_config

  source_dir = local.server_options.package.source_dir
  output_dir = local.server_options.package.output_dir

  vpc_id                       = local.server_options.networking.vpc_id
  subnet_ids                   = local.server_options.networking.subnet_ids
  security_group_ingress_rules = local.server_options.networking.security_group_ingress_rules
  security_group_egress_rules  = local.server_options.networking.security_group_egress_rules

  environment_variables = local.server_options.environment_variables
  iam_policy_statements = local.server_options.iam_policy_statements
}


/**
 * Image Optimization Function
 **/
locals {
  image_optimization_options = {
    package = {
      source_dir = coalesce(try(var.image_optimization_options.source_dir, null), "${local.opennext_abs_path}/image-optimization-function/")
      output_dir = coalesce(try(var.image_optimization_options.output_dir, null), "/tmp/")
    }

    lambda = {
      function_name                  = try(var.image_optimization_options.lambda.function_name, null)
      description                    = coalesce(try(var.image_optimization_options.lambda.description, null), "Next.js Image Optimization")
      handler                        = coalesce(try(var.image_optimization_options.lambda.handler, null), "index.handler")
      runtime                        = coalesce(try(var.image_optimization_options.lambda.runtime, null), "nodejs18.x")
      architectures                  = coalesce(try(var.image_optimization_options.lambda.architectures, null), ["arm64"])
      memory_size                    = coalesce(try(var.image_optimization_options.lambda.memory_size, null), 512)
      timeout                        = coalesce(try(var.image_optimization_options.lambda.timeout, null), 30)
      publish                        = coalesce(try(var.image_optimization_options.lambda.publish, null), false)
      dead_letter_config             = try(var.image_optimization_options.lambda.dead_letter_config, null)
      reserved_concurrent_executions = coalesce(try(var.image_optimization_options.lambda.reserved_concurrent_executions, null), 3)
      code_signing_config            = try(var.image_optimization_options.lambda.code_signing_config, null)
    }

    networking = {
      vpc_id                       = try(var.image_optimization_options.networking.vpc_id, null)
      subnet_ids                   = coalesce(try(var.image_optimization_options.networking.subnet_ids, null), [])
      security_group_ingress_rules = coalesce(try(var.image_optimization_options.networking.sg_ingress_rules, null), [])
      security_group_egress_rules  = coalesce(try(var.image_optimization_options.networking.sg_egress_rules, null), [])
    }

    environment_variables = merge({
      BUCKET_NAME       = module.assets.assets_bucket.bucket,
      BUCKET_KEY_PREFIX = "assets"
    }, coalesce(try(var.image_optimization_options.environment_variables, null), {}))

    iam_policy_statements = concat([
      {
        effect    = "Allow"
        actions   = ["s3:GetObject"]
        resources = [module.assets.assets_bucket.arn, "${module.assets.assets_bucket.arn}/*"]
      }
    ], coalesce(try(var.image_optimization_options.iam_policy, null), []))
  }
}

module "image_optimization_function" {
  source = "./modules/opennext-lambda"

  prefix = "${var.prefix}-nextjs-image-optimization"

  function_name                  = local.image_optimization_options.lambda.function_name
  description                    = local.image_optimization_options.lambda.description
  handler                        = local.image_optimization_options.lambda.handler
  runtime                        = local.image_optimization_options.lambda.runtime
  architectures                  = local.image_optimization_options.lambda.architectures
  memory_size                    = local.image_optimization_options.lambda.memory_size
  timeout                        = local.image_optimization_options.lambda.timeout
  publish                        = local.image_optimization_options.lambda.publish
  dead_letter_config             = local.image_optimization_options.lambda.dead_letter_config
  reserved_concurrent_executions = local.image_optimization_options.lambda.reserved_concurrent_executions
  code_signing_config            = local.image_optimization_options.lambda.code_signing_config

  source_dir = local.image_optimization_options.package.source_dir
  output_dir = local.image_optimization_options.package.output_dir

  vpc_id                       = local.image_optimization_options.networking.vpc_id
  subnet_ids                   = local.image_optimization_options.networking.subnet_ids
  security_group_ingress_rules = local.image_optimization_options.networking.security_group_ingress_rules
  security_group_egress_rules  = local.image_optimization_options.networking.security_group_egress_rules

  environment_variables = local.image_optimization_options.environment_variables
  iam_policy_statements = local.image_optimization_options.iam_policy_statements
}

/**
 * ISR Revalidation Function
 **/
locals {
  revalidation_options = {
    package = {
      source_dir = coalesce(try(var.revalidation_options.source_dir, null), "${local.opennext_abs_path}/revalidation-function/")
      output_dir = coalesce(try(var.revalidation_options.output_dir, null), "/tmp/")
    }

    lambda = {
      function_name                  = try(var.revalidation_options.lambda.function_name, null)
      description                    = coalesce(try(var.revalidation_options.lambda.description, null), "Next.js ISR Revalidation Function")
      handler                        = coalesce(try(var.revalidation_options.lambda.handler, null), "index.handler")
      runtime                        = coalesce(try(var.revalidation_options.lambda.runtime, null), "nodejs18.x")
      architectures                  = coalesce(try(var.revalidation_options.lambda.architectures, null), ["arm64"])
      memory_size                    = coalesce(try(var.revalidation_options.lambda.memory_size, null), 128)
      timeout                        = coalesce(try(var.revalidation_options.lambda.timeout, null), 30)
      publish                        = coalesce(try(var.revalidation_options.lambda.publish, null), false)
      dead_letter_config             = try(var.revalidation_options.lambda.dead_letter_config, null)
      reserved_concurrent_executions = coalesce(try(var.revalidation_options.lambda.reserved_concurrent_executions, null), 3)
      code_signing_config            = try(var.revalidation_options.lambda.code_signing_config, null)
    }

    networking = {
      vpc_id                       = try(var.revalidation_options.networking.vpc_id, null)
      subnet_ids                   = coalesce(try(var.revalidation_options.networking.subnet_ids, null), [])
      security_group_ingress_rules = coalesce(try(var.revalidation_options.networking.sg_ingress_rules, null), [])
      security_group_egress_rules  = coalesce(try(var.revalidation_options.networking.sg_egress_rules, null), [])
    }

    environment_variables = coalesce(try(var.revalidation_options.environment_variables, null), {})

    iam_policy_statements = concat([
      {
        effect    = "Allow"
        actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        resources = [module.revalidation_queue.queue.arn]
      }
    ], coalesce(try(var.revalidation_options.iam_policy, null), []))
  }
}

module "revalidation_function" {
  source = "./modules/opennext-lambda"

  prefix = "${var.prefix}-nextjs-revalidation"

  function_name                  = local.revalidation_options.lambda.function_name
  description                    = local.revalidation_options.lambda.description
  handler                        = local.revalidation_options.lambda.handler
  runtime                        = local.revalidation_options.lambda.runtime
  architectures                  = local.revalidation_options.lambda.architectures
  memory_size                    = local.revalidation_options.lambda.memory_size
  timeout                        = local.revalidation_options.lambda.timeout
  publish                        = local.revalidation_options.lambda.publish
  dead_letter_config             = local.revalidation_options.lambda.dead_letter_config
  reserved_concurrent_executions = local.revalidation_options.lambda.reserved_concurrent_executions
  code_signing_config            = local.revalidation_options.lambda.code_signing_config

  source_dir = local.revalidation_options.package.source_dir
  output_dir = local.revalidation_options.package.output_dir

  vpc_id                       = local.revalidation_options.networking.vpc_id
  subnet_ids                   = local.revalidation_options.networking.subnet_ids
  security_group_ingress_rules = local.revalidation_options.networking.security_group_ingress_rules
  security_group_egress_rules  = local.revalidation_options.networking.security_group_egress_rules

  environment_variables = local.revalidation_options.environment_variables
  iam_policy_statements = local.revalidation_options.iam_policy_statements
}

/**
 * ISR Revalidation Queue
 **/
module "revalidation_queue" {
  source = "./modules/opennext-revalidation-queue"
  prefix = "${var.prefix}-revalidation-queue"

  aws_account_id            = data.aws_caller_identity.current.account_id
  revalidation_function_arn = module.revalidation_function.lambda_function.arn
}

/**
 * Warmer Function
 **/
locals {
  warmer_options = {
    package = {
      source_dir = coalesce(try(var.warmer_options.source_dir, null), "${local.opennext_abs_path}/warmer-function/")
      output_dir = coalesce(try(var.warmer_options.output_dir, null), "/tmp/")
    }

    lambda = {
      function_name                  = try(var.warmer_options.lambda.function_name, null)
      description                    = coalesce(try(var.warmer_options.lambda.description, null), "Next.js Warmer Function")
      handler                        = coalesce(try(var.warmer_options.lambda.handler, null), "index.handler")
      runtime                        = coalesce(try(var.warmer_options.lambda.runtime, null), "nodejs18.x")
      architectures                  = coalesce(try(var.warmer_options.lambda.architectures, null), ["arm64"])
      memory_size                    = coalesce(try(var.warmer_options.lambda.memory_size, null), 128)
      timeout                        = coalesce(try(var.warmer_options.lambda.timeout, null), 30)
      publish                        = coalesce(try(var.warmer_options.lambda.publish, null), false)
      dead_letter_config             = try(var.warmer_options.lambda.dead_letter_config, null)
      reserved_concurrent_executions = coalesce(try(var.warmer_options.lambda.reserved_concurrent_executions, null), 3)
      code_signing_config            = try(var.warmer_options.lambda.code_signing_config, null)

    }

    networking = {
      vpc_id                       = try(var.warmer_options.networking.vpc_id, null)
      subnet_ids                   = coalesce(try(var.warmer_options.networking.subnet_ids, null), [])
      security_group_ingress_rules = coalesce(try(var.warmer_options.networking.sg_ingress_rules, null), [])
      security_group_egress_rules  = coalesce(try(var.warmer_options.networking.sg_egress_rules, null), [])
    }

    environment_variables = merge({
      FUNCTION_NAME = module.server_function.lambda_function.function_name,
      CONCURRENCY   = 1
    }, coalesce(try(var.warmer_options.environment_variables, null), {}))

    iam_policy_statements = concat([
      {
        effect    = "Allow"
        actions   = ["lambda:InvokeFunction"]
        resources = [module.server_function.lambda_function.arn]
      }
    ], coalesce(try(var.warmer_options.iam_policy, null), []))
  }
}
module "warmer_function" {
  source = "./modules/opennext-lambda"

  prefix                            = "${var.prefix}-nextjs-warmer"
  create_eventbridge_scheduled_rule = true


  function_name                  = local.warmer_options.lambda.function_name
  description                    = local.warmer_options.lambda.description
  handler                        = local.warmer_options.lambda.handler
  runtime                        = local.warmer_options.lambda.runtime
  architectures                  = local.warmer_options.lambda.architectures
  memory_size                    = local.warmer_options.lambda.memory_size
  timeout                        = local.warmer_options.lambda.timeout
  publish                        = local.warmer_options.lambda.publish
  dead_letter_config             = local.warmer_options.lambda.dead_letter_config
  reserved_concurrent_executions = local.warmer_options.lambda.reserved_concurrent_executions
  code_signing_config            = local.warmer_options.lambda.code_signing_config

  source_dir = local.warmer_options.package.source_dir
  output_dir = local.warmer_options.package.output_dir

  vpc_id                       = local.warmer_options.networking.vpc_id
  subnet_ids                   = local.warmer_options.networking.subnet_ids
  security_group_ingress_rules = local.warmer_options.networking.security_group_ingress_rules
  security_group_egress_rules  = local.warmer_options.networking.security_group_egress_rules

  environment_variables = local.warmer_options.environment_variables
  iam_policy_statements = local.warmer_options.iam_policy_statements
}

/**
 * CloudFront -> CloudWatch Logs
 **/
module "cloudfront_logs" {
  source = "./modules/cloudfront-logs"

  log_group_name  = "${var.prefix}-cloudfront-logs"
  log_bucket_name = "${var.prefix}-cloudfront-logs"
  retention       = 365
}

/**
 * Next.js CloudFront Distribution
 **/
locals {
  cloudfront = {
    aliases             = var.cloudfront.aliases
    acm_certificate_arn = var.cloudfront.acm_certificate_arn
    assets_paths        = coalesce(var.cloudfront.assets_paths, [])
    custom_headers      = coalesce(var.cloudfront.custom_headers, [])
    cors = merge({
      allow_credentials = false,
      allow_headers     = ["*"],
      allow_methods     = ["ALL"],
      allow_origins     = ["*"],
      origin_override   = true
    }, var.cloudfront.cors)
    hsts = merge({
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
      preload                    = true
    }, var.cloudfront.hsts)
    waf_logging_configuration = var.cloudfront.waf_logging_configuration
  }
}

module "cloudfront" {
  source = "./modules/opennext-cloudfront"
  prefix = "${var.prefix}-cloudfront"

  logging_bucket_domain_name    = module.cloudfront_logs.logs_s3_bucket.bucket_regional_domain_name
  assets_origin_access_identity = module.assets.cloudfront_origin_access_identity.cloudfront_access_identity_path
  origins = {
    assets_bucket               = module.assets.assets_bucket.bucket_regional_domain_name
    server_function             = "${module.server_function.lambda_function_url.url_id}.lambda-url.eu-west-2.on.aws"
    image_optimization_function = "${module.image_optimization_function.lambda_function_url.url_id}.lambda-url.eu-west-2.on.aws"
  }

  aliases                   = local.cloudfront.aliases
  acm_certificate_arn       = local.cloudfront.acm_certificate_arn
  assets_paths              = local.cloudfront.assets_paths
  custom_headers            = local.cloudfront.custom_headers
  cors                      = local.cloudfront.cors
  hsts                      = local.cloudfront.hsts
  waf_logging_configuration = local.cloudfront.waf_logging_configuration
}
