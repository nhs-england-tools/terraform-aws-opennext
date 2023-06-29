locals {
  server_origin_id             = "${var.prefix}-server"
  static_assets_origin_id      = "${var.prefix}-static-assets"
  image_optimization_origin_id = "${var.prefix}-image-optimization"
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

resource "aws_cloudfront_cache_policy" "cache_policy" {
  name = "${var.prefix}-cloudfront-cache-policy"

  default_ttl = 0
  max_ttl     = 31536000
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "all"
    }

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["accept", "rsc", "next-router-prefetch", "next-router-state-tree"]
      }
    }

    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

resource "aws_cloudfront_response_headers_policy" "response_headers_policy" {
  name    = "${var.prefix}-cloudfront-response-headers-policy"
  comment = "${var.prefix} CloudFront Response Headers Policy"

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

  custom_headers_config {
    dynamic "items" {
      for_each = var.custom_headers

      content {
        header   = items.header
        override = items.override
        value    = items.value
      }
    }
  }
}

data "aws_cloudfront_origin_request_policy" "origin_request_policy" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "aws_cloudfront_distribution" "next_distribution" {
  # checkov:skip=CKV_AWS_310:Failover origin not required for Open-Next
  # checkov:skip=CKV2_AWS_47:Log4j Vulnerability handled in WAF ACL

  provider            = aws.global
  price_class         = "PriceClass_100"
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.prefix} - CloudFront Distribution for Next.js Application"
  aliases             = var.aliases
  web_acl_id          = aws_wafv2_web_acl.cloudfront_waf.arn
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = module.cloudfront_logs.logs_s3_bucket.bucket_regional_domain_name
    prefix          = one(var.aliases)
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      # TODO: Remove US location after implementing GitHub Self-Hosted runners
      locations = ["GB", "US"]
    }
  }

  # S3 Bucket Origin
  origin {
    domain_name = aws_s3_bucket.static_assets.bucket_regional_domain_name
    origin_id   = local.static_assets_origin_id
    origin_path = "/assets"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.static_assets.cloudfront_access_identity_path
    }
  }

  # Server Function Origin
  origin {
    domain_name = "${module.server_function.lambda_function_url_id}.lambda-url.eu-west-2.on.aws"
    origin_id   = local.server_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Image Optimization Function Origin
  origin {
    domain_name = "${module.image_optimization_function.lambda_function_url_id}.lambda-url.eu-west-2.on.aws"
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
    target_origin_id = local.static_assets_origin_id

    response_headers_policy_id = aws_cloudfront_response_headers_policy.response_headers_policy.id
    cache_policy_id            = aws_cloudfront_cache_policy.cache_policy.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.origin_request_policy.id

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
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.origin_request_policy.id

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
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.origin_request_policy.id

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
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.origin_request_policy.id

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
    target_origin_id = local.static_assets_origin_id

    response_headers_policy_id = aws_cloudfront_response_headers_policy.response_headers_policy.id
    cache_policy_id            = aws_cloudfront_cache_policy.cache_policy.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.origin_request_policy.id

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  dynamic "ordered_cache_behavior" {
    for_each = toset(var.assets_paths)

    content {
      path_pattern     = ordered_cache_behavior.value
      allowed_methods  = ["GET", "HEAD", "OPTIONS"]
      cached_methods   = ["GET", "HEAD", "OPTIONS"]
      target_origin_id = local.static_assets_origin_id

      response_headers_policy_id = aws_cloudfront_response_headers_policy.response_headers_policy.id
      cache_policy_id            = aws_cloudfront_cache_policy.cache_policy.id
      origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.origin_request_policy.id

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
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.origin_request_policy.id

    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.host_header_function.arn
    }
  }
}