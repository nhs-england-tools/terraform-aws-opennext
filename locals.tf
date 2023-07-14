locals {
  opennext_abs_path = "${abspath(path.root)}/${var.opennext_build_path}"
}

locals {
  /**
   * CloudFront Options
   **/
  cloudfront = {
    aliases             = var.cloudfront.aliases
    acm_certificate_arn = var.cloudfront.acm_certificate_arn
    assets_paths        = coalesce(var.cloudfront.assets_paths, [])
    custom_headers      = coalesce(var.cloudfront.custom_headers, [])
    geo_restriction = coalesce(try(var.cloudfront.geo_restriction, null), {
      restriction_type = "none"
      locations        = []
    })
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
    cache_policy = {
      default_ttl = coalesce(try(var.cloudfront.cache_policy.default_ttl, null), 0)
      min_ttl     = coalesce(try(var.cloudfront.cache_policy.min_ttl, null), 0)
      max_ttl     = coalesce(try(var.cloudfront.cache_policy.max_ttl, null), 31536000)
      cookies_config = merge({
        cookie_behavior = "all"
      }, try(var.cloudfront.cache_policy.cookies_config, {}))
      headers_config = merge({
        header_behavior = "whitelist",
        items           = []
      }, try(var.cloudfront.cache_policy.headers_config, {}))
      query_strings_config = merge({
        query_string_behavior = "all",
        items                 = []
      }, try(var.cloudfront.cache_policy.query_strings_config, {}))
    }
    origin_request_policy = try(var.cloudfront.origin_request_policy, null)
  }

  /**
   * Server Function Options
   **/
  server_options = {
    package = {
      source_dir = coalesce(try(var.server_options.package.source_dir, null), "${local.opennext_abs_path}/server-function/")
      output_dir = coalesce(try(var.server_options.package.output_dir, null), "${local.opennext_abs_path}/.build/")
    }

    function = {
      function_name                  = try(var.server_options.function.function_name, null)
      description                    = coalesce(try(var.server_options.function.description, null), "Next.js Server")
      handler                        = coalesce(try(var.server_options.function.handler, null), "index.handler")
      runtime                        = coalesce(try(var.server_options.function.runtime, null), "nodejs18.x")
      architectures                  = coalesce(try(var.server_options.function.architectures, null), ["arm64"])
      memory_size                    = coalesce(try(var.server_options.function.memory_size, null), 512)
      timeout                        = coalesce(try(var.server_options.function.timeout, null), 30)
      publish                        = coalesce(try(var.server_options.function.publish, null), false)
      dead_letter_config             = try(var.server_options.function.dead_letter_config, null)
      reserved_concurrent_executions = coalesce(try(var.server_options.function.reserved_concurrent_executions, null), 10)
      code_signing_config            = try(var.server_options.function.code_signing_config, null)
    }

    log_group = {
      retention_in_days = coalesce(try(var.server_options.log_group.retention_in_days, null), 365)
      kms_key_id        = try(var.server_options.log_group.kms_key_id, null)
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
      },
      {
        effect    = "Allow"
        actions   = ["kms:GenerateDataKey", "kms:Decrypt"]
        resources = [module.revalidation_queue.queue_kms_key.arn]
      }
    ], coalesce(try(var.server_options.iam_policy, null), []))
  }

  /**
   * Image Optimization Function Options
   **/
  image_optimization_options = {
    package = {
      source_dir = coalesce(try(var.image_optimization_options.package.source_dir, null), "${local.opennext_abs_path}/image-optimization-function/")
      output_dir = coalesce(try(var.image_optimization_options.package.output_dir, null), "${local.opennext_abs_path}/.build/")
    }

    function = {
      function_name                  = try(var.image_optimization_options.function.function_name, null)
      description                    = coalesce(try(var.image_optimization_options.function.description, null), "Next.js Image Optimization")
      handler                        = coalesce(try(var.image_optimization_options.function.handler, null), "index.handler")
      runtime                        = coalesce(try(var.image_optimization_options.function.runtime, null), "nodejs18.x")
      architectures                  = coalesce(try(var.image_optimization_options.function.architectures, null), ["arm64"])
      memory_size                    = coalesce(try(var.image_optimization_options.function.memory_size, null), 512)
      timeout                        = coalesce(try(var.image_optimization_options.function.timeout, null), 30)
      publish                        = coalesce(try(var.image_optimization_options.function.publish, null), false)
      dead_letter_config             = try(var.image_optimization_options.function.dead_letter_config, null)
      reserved_concurrent_executions = coalesce(try(var.image_optimization_options.function.reserved_concurrent_executions, null), 3)
      code_signing_config            = try(var.image_optimization_options.function.code_signing_config, null)
    }

    log_group = {
      retention_in_days = coalesce(try(var.image_optimization_options.log_group.retention_in_days, null), 365)
      kms_key_id        = try(var.image_optimization_options.log_group.kms_key_id, null)
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


  /**
   * ISR Revalidation Function Options
   **/
  revalidation_options = {
    package = {
      source_dir = coalesce(try(var.revalidation_options.package.source_dir, null), "${local.opennext_abs_path}/revalidation-function/")
      output_dir = coalesce(try(var.revalidation_options.package.output_dir, null), "${local.opennext_abs_path}/.build/")
    }

    function = {
      function_name                  = try(var.revalidation_options.function.function_name, null)
      description                    = coalesce(try(var.revalidation_options.function.description, null), "Next.js ISR Revalidation Function")
      handler                        = coalesce(try(var.revalidation_options.function.handler, null), "index.handler")
      runtime                        = coalesce(try(var.revalidation_options.function.runtime, null), "nodejs18.x")
      architectures                  = coalesce(try(var.revalidation_options.function.architectures, null), ["arm64"])
      memory_size                    = coalesce(try(var.revalidation_options.function.memory_size, null), 128)
      timeout                        = coalesce(try(var.revalidation_options.function.timeout, null), 30)
      publish                        = coalesce(try(var.revalidation_options.function.publish, null), false)
      dead_letter_config             = try(var.revalidation_options.function.dead_letter_config, null)
      reserved_concurrent_executions = coalesce(try(var.revalidation_options.function.reserved_concurrent_executions, null), 3)
      code_signing_config            = try(var.revalidation_options.function.code_signing_config, null)
    }

    log_group = {
      retention_in_days = coalesce(try(var.revalidation_options.log_group.retention_in_days, null), 365)
      kms_key_id        = try(var.revalidation_options.log_group.kms_key_id, null)
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
      },
      {
        effect    = "Allow"
        actions   = ["kms:Decrypt", "kms:DescribeKey"]
        resources = [module.revalidation_queue.queue_kms_key.arn]
      }
    ], coalesce(try(var.revalidation_options.iam_policy, null), []))
  }

  /**
   * Warmer Function Options
   **/
  warmer_options = {
    package = {
      source_dir = coalesce(try(var.warmer_options.package.source_dir, null), "${local.opennext_abs_path}/warmer-function/")
      output_dir = coalesce(try(var.warmer_options.package.output_dir, null), "${local.opennext_abs_path}/.build/")
    }

    function = {
      function_name                  = try(var.warmer_options.function.function_name, null)
      description                    = coalesce(try(var.warmer_options.function.description, null), "Next.js Warmer Function")
      handler                        = coalesce(try(var.warmer_options.function.handler, null), "index.handler")
      runtime                        = coalesce(try(var.warmer_options.function.runtime, null), "nodejs18.x")
      architectures                  = coalesce(try(var.warmer_options.function.architectures, null), ["arm64"])
      memory_size                    = coalesce(try(var.warmer_options.function.memory_size, null), 128)
      timeout                        = coalesce(try(var.warmer_options.function.timeout, null), 30)
      publish                        = coalesce(try(var.warmer_options.function.publish, null), false)
      dead_letter_config             = try(var.warmer_options.function.dead_letter_config, null)
      reserved_concurrent_executions = coalesce(try(var.warmer_options.function.reserved_concurrent_executions, null), 3)
      code_signing_config            = try(var.warmer_options.function.code_signing_config, null)
    }

    log_group = {
      retention_in_days = coalesce(try(var.warmer_options.log_group.retention_in_days, null), 365)
      kms_key_id        = try(var.warmer_options.log_group.kms_key_id, null)
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
