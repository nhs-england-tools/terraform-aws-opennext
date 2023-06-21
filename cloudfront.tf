locals {
    server_origin_id = "${var.prefix}-server"
    static_assets_origin_id = "${var.prefix}-static-assets"
    failover_origin_id = "${var.prefix}-failover"
    image_optimization_origin_id = "${var.prefix}-image-optimization"
}

resource "aws_cloudfront_distribution" "next_distribution" {
  price_class     = "PriceClass_100"
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.prefix} - CloudFront Distribution for Next.js Application"
  aliases         = [var.domain_name]
  web_acl_id = aws_wafv2_web_acl.cloudfront_waf.id

  logging_config {
    include_cookies = false
    bucket = module.cloudfront_logs.logs_s3_bucket.bucket
    prefix = var.domain_name
  }

  origin {
    domain_name = aws_s3_bucket.static_assets.bucket_regional_domain_name
    origin_id   = local.static_assets_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.static_assets.cloudfront_access_identity_path
    }
  }

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

  default_cache_behavior {
    allowed_methods        = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = local.server_origin_id
    viewer_protocol_policy = "redirect-to-https"

    function_association {
      event_type = "viewer-request"
      function_arn = aws_cloudfront_function.host_header_function.arn
    }

    forwarded_values {
      query_string = true
      headers      = ["Origin"]

      cookies {
        forward           = "all"
      }
    }
  }

  ordered_cache_behavior {
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD", "OPTIONS"]
    path_pattern             = "/_next/static/*"
    target_origin_id         = local.static_assets_origin_id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.static_assets_origin_request_policy.id
    cache_policy_id          = aws_cloudfront_cache_policy.static_assets_origin_cache_policy.id
    viewer_protocol_policy   = "redirect-to-https"
  }

  ordered_cache_behavior {
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD", "OPTIONS"]
    path_pattern             = "/_next/data/*"
    target_origin_id         = local.static_assets_origin_id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.static_assets_origin_request_policy.id
    cache_policy_id          = aws_cloudfront_cache_policy.static_assets_origin_cache_policy.id
    viewer_protocol_policy   = "redirect-to-https"
  }

  ordered_cache_behavior {
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD", "OPTIONS"]
    path_pattern             = "/_next/image"
    target_origin_id         = local.image_optimization_origin_id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.image_optimization_origin_request_policy.id
    cache_policy_id          = aws_cloudfront_cache_policy.image_optimization_origin_cache_policy.id
    viewer_protocol_policy   = "redirect-to-https"

  }

  ordered_cache_behavior {
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD", "OPTIONS"]
    path_pattern             = "/api/*"
    target_origin_id         = local.server_origin_id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.server_origin_request_policy.id
    cache_policy_id          = aws_cloudfront_cache_policy.server_origin_cache_policy.id
    viewer_protocol_policy   = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern           = "/favicon.ico"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.static_assets_origin_id
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }
}

resource "aws_cloudfront_origin_request_policy" "server_origin_request_policy" {
  name = "${var.prefix}-server-origin-request-policy"

  cookies_config {
    cookie_behavior = "whitelist"
    cookies {
      items = ["session_id"]
    }
  }

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Origin"]
    }
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

resource "aws_cloudfront_cache_policy" "server_origin_cache_policy" {
  name        = "${var.prefix}-server-origin-cache-policy"
  default_ttl = 86400
  min_ttl     = 0
  max_ttl     = 31536000

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "all"
    }
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Origin"]
      }
    }
    query_strings_config {
      query_string_behavior = "all"
    }
  }
}


resource "aws_cloudfront_origin_request_policy" "image_optimization_origin_request_policy" {
  name = "${var.prefix}-image-optimization-origin-request-policy"
  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "none"
  }
  query_strings_config {
    query_string_behavior = "all"
  }
}

resource "aws_cloudfront_cache_policy" "image_optimization_origin_cache_policy" {
  name        = "${var.prefix}-image-optimization-origin-cache-policy"
  default_ttl = 86400
  min_ttl     = 0
  max_ttl     = 31536000

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "all"
    }
  }
}


resource "aws_cloudfront_origin_request_policy" "static_assets_origin_request_policy" {
  name = "${var.prefix}-static-assets-origin-request-policy"
  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "none"
  }
  query_strings_config {
    query_string_behavior = "none"
  }
}

resource "aws_cloudfront_cache_policy" "static_assets_origin_cache_policy" {
  name        = "${var.prefix}-static-assets-origin-cache-policy"
  default_ttl = 86400
  min_ttl     = 0
  max_ttl     = 31536000

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
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
