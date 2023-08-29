locals {
  server_origin_id             = "${var.prefix}-server-origin"
  assets_origin_id             = "${var.prefix}-assets-origin"
  image_optimization_origin_id = "${var.prefix}-image-optimization-origin"
}

resource "aws_cloudfront_function" "host_header_function" {
  name    = "${var.prefix}-preserve-host"
  runtime = "cloudfront-js-1.0"
  comment = "Next.js Function for Preserving Original Host"
  publish = true
  code    = <<EOF
function handler(event) {
  var request = event.request;
  request.headers["x-forwarded-host"] = request.headers.host;
  return request;
}
EOF
}

data "aws_cloudfront_origin_request_policy" "origin_request_policy" {
  count = var.origin_request_policy == null ? 1 : 0
  name  = "Managed-AllViewerExceptHostHeader"
}

resource "aws_cloudfront_origin_request_policy" "origin_request_policy" {
  count = var.origin_request_policy == null ? 0 : 1
  name  = "${var.prefix}-origin-request-policy"

  cookies_config {
    cookie_behavior = var.origin_request_policy.cookies_config.cookie_behavior
    cookies {
      items = var.origin_request_policy.cookies_config.items
    }
  }

  headers_config {
    header_behavior = var.origin_request_policy.headers_config.header_behavior

    headers {
      items = concat(
        ["accept", "rsc", "next-router-prefetch", "next-router-state-tree", "x-prerender-revalidate"],
        coalesce(var.origin_request_policy.headers_config.items, [])
      )
    }
  }

  query_strings_config {
    query_string_behavior = var.origin_request_policy.query_strings_config.query_string_behavior
    query_strings {
      items = var.origin_request_policy.query_strings_config.items
    }
  }
}

resource "aws_cloudfront_cache_policy" "cache_policy" {
  name = "${var.prefix}-cache-policy"

  default_ttl = var.cache_policy.default_ttl
  min_ttl     = var.cache_policy.min_ttl
  max_ttl     = var.cache_policy.max_ttl

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = var.cache_policy.enable_accept_encoding_brotli
    enable_accept_encoding_gzip   = var.cache_policy.enable_accept_encoding_gzip

    cookies_config {
      cookie_behavior = var.cache_policy.cookies_config.cookie_behavior

      dynamic "cookies" {
        for_each = var.cache_policy.cookies_config.items != null ? [true] : []

        content {
          items = var.cache_policy.cookies_config.items
        }
      }
    }

    headers_config {
      header_behavior = var.cache_policy.headers_config.header_behavior

      headers {
        items = concat(
          ["accept", "rsc", "next-router-prefetch", "next-router-state-tree", "x-prerender-revalidate"],
          coalesce(var.cache_policy.headers_config.items, [])
        )
      }
    }

    query_strings_config {
      query_string_behavior = var.cache_policy.query_strings_config.query_string_behavior

      dynamic "query_strings" {
        for_each = var.cache_policy.query_strings_config.items != null ? [true] : []

        content {
          items = var.cache_policy.query_strings_config.items
        }
      }
    }
  }
}

resource "aws_cloudfront_response_headers_policy" "response_headers_policy" {
  name    = "${var.prefix}-response-headers-policy"
  comment = "${var.prefix} Response Headers Policy"

  cors_config {
    origin_override                  = var.cors.origin_override
    access_control_allow_credentials = var.cors.allow_credentials

    access_control_allow_headers {
      items = var.cors.allow_headers
    }

    access_control_allow_methods {
      items = var.cors.allow_methods
    }

    access_control_allow_origins {
      items = var.cors.allow_origins
    }
  }

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = var.hsts.access_control_max_age_sec
      include_subdomains         = var.hsts.include_subdomains
      override                   = var.hsts.override
      preload                    = var.hsts.preload
    }
  }

  dynamic "custom_headers_config" {
    for_each = length(var.custom_headers) > 0 ? [true] : []

    content {
      dynamic "items" {
        for_each = toset(var.custom_headers)

        content {
          header   = items.header
          override = items.override
          value    = items.value
        }
      }
    }
  }
  dynamic "remove_headers_config" {
    for_each = length(var.remove_headers_config.items) > 0 ? [true] : []

    content {
      dynamic "items" {
        for_each = toset(var.remove_headers_config.items)

        content {
          header = items.value
        }
      }
    }
  }
}

resource "aws_cloudfront_distribution" "distribution" {
  provider        = aws.global
  price_class     = "PriceClass_100"
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.prefix} - CloudFront Distribution for Next.js Application"
  aliases         = var.aliases
  web_acl_id      = aws_wafv2_web_acl.cloudfront_waf.arn

  logging_config {
    include_cookies = false
    # bucket          = module.cloudfront_logs.logs_s3_bucket.bucket_regional_domain_name
    bucket = var.logging_bucket_domain_name
    prefix = one(var.aliases)
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction.restriction_type
      locations        = var.geo_restriction.locations
    }
  }

  # S3 Bucket Origin
  origin {
    domain_name = var.origins.assets_bucket
    origin_id   = local.assets_origin_id
    origin_path = "/assets"

    s3_origin_config {
      origin_access_identity = var.assets_origin_access_identity
    }
  }

  # Server Function Origin
  origin {
    domain_name = var.origins.server_function
    # domain_name = "${module.server_function.lambda_function_url_id}.lambda-url.eu-west-2.on.aws"
    origin_id = local.server_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Image Optimization Function Origin
  origin {
    # domain_name = "${module.image_optimization_function.lambda_function_url_id}.lambda-url.eu-west-2.on.aws"
    domain_name = var.origins.image_optimization_function
    origin_id   = local.image_optimization_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Behaviour - Hashed Static Files (/_next/static/*)
  ordered_cache_behavior {
    path_pattern     = "/_next/static/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.assets_origin_id

    response_headers_policy_id = aws_cloudfront_response_headers_policy.response_headers_policy.id
    cache_policy_id            = aws_cloudfront_cache_policy.cache_policy.id
    origin_request_policy_id = try(
      data.aws_cloudfront_origin_request_policy.origin_request_policy[0].id,
      aws_cloudfront_origin_request_policy.origin_request_policy[0].id
    )

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern     = "/_next/image"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.image_optimization_origin_id

    response_headers_policy_id = aws_cloudfront_response_headers_policy.response_headers_policy.id
    cache_policy_id            = aws_cloudfront_cache_policy.cache_policy.id
    origin_request_policy_id = try(
      data.aws_cloudfront_origin_request_policy.origin_request_policy[0].id,
      aws_cloudfront_origin_request_policy.origin_request_policy[0].id
    )

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern     = "/_next/data/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.server_origin_id

    response_headers_policy_id = aws_cloudfront_response_headers_policy.response_headers_policy.id
    cache_policy_id            = aws_cloudfront_cache_policy.cache_policy.id
    origin_request_policy_id = try(
      data.aws_cloudfront_origin_request_policy.origin_request_policy[0].id,
      aws_cloudfront_origin_request_policy.origin_request_policy[0].id
    )

    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.host_header_function.arn
    }
  }

  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.server_origin_id

    response_headers_policy_id = aws_cloudfront_response_headers_policy.response_headers_policy.id
    cache_policy_id            = aws_cloudfront_cache_policy.cache_policy.id
    origin_request_policy_id = try(
      data.aws_cloudfront_origin_request_policy.origin_request_policy[0].id,
      aws_cloudfront_origin_request_policy.origin_request_policy[0].id
    )

    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.host_header_function.arn
    }
  }

  ordered_cache_behavior {
    path_pattern     = "/favicon.ico"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.assets_origin_id

    response_headers_policy_id = aws_cloudfront_response_headers_policy.response_headers_policy.id
    cache_policy_id            = aws_cloudfront_cache_policy.cache_policy.id
    origin_request_policy_id = try(
      data.aws_cloudfront_origin_request_policy.origin_request_policy[0].id,
      aws_cloudfront_origin_request_policy.origin_request_policy[0].id
    )

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  dynamic "ordered_cache_behavior" {
    for_each = toset(var.assets_paths)

    content {
      path_pattern     = ordered_cache_behavior.value
      allowed_methods  = ["GET", "HEAD", "OPTIONS"]
      cached_methods   = ["GET", "HEAD", "OPTIONS"]
      target_origin_id = local.assets_origin_id

      response_headers_policy_id = aws_cloudfront_response_headers_policy.response_headers_policy.id
      cache_policy_id            = aws_cloudfront_cache_policy.cache_policy.id
      origin_request_policy_id = try(
        data.aws_cloudfront_origin_request_policy.origin_request_policy[0].id,
        aws_cloudfront_origin_request_policy.origin_request_policy[0].id
      )

      compress               = true
      viewer_protocol_policy = "redirect-to-https"
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.server_origin_id

    response_headers_policy_id = aws_cloudfront_response_headers_policy.response_headers_policy.id
    cache_policy_id            = aws_cloudfront_cache_policy.cache_policy.id
    origin_request_policy_id = try(
      data.aws_cloudfront_origin_request_policy.origin_request_policy[0].id,
      aws_cloudfront_origin_request_policy.origin_request_policy[0].id
    )

    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.host_header_function.arn
    }
  }
}
