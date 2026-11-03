/**
 * Static Assets S3 Bucket
 **/
locals {
  content_type_lookup = {
    css   = "text/css"
    woff2 = "font/woff2"
    js    = "text/javascript"
    svg   = "image/svg+xml"
    ico   = "image/x-icon"
    html  = "text/html"
    htm   = "text/html"
    json  = "application/json"
    png   = "image/png"
    jpg   = "image/jpeg"
    jpeg  = "image/jpeg"
  }
}

resource "aws_s3_bucket" "assets" {
  bucket = var.prefix
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.bucket

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.bucket
  policy = data.aws_iam_policy_document.read_assets_bucket.json
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.bucket

  rule {

    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "logs" {
  count = var.replication_configuration == null ? 0 : 1

  depends_on = [aws_s3_bucket_versioning.assets]
  bucket     = aws_s3_bucket.assets.bucket
  role       = var.replication_configuration.role

  dynamic "rule" {
    for_each = toset(var.replication_configuration.rules)

    content {
      id     = rule.value.id
      status = rule.value.status

      dynamic "filter" {
        for_each = toset(rule.value.filters)

        content {
          prefix = filter.value.prefix
        }
      }

      destination {
        bucket        = rule.value.destination.bucket
        storage_class = rule.value.destination.storage_class
      }
    }
  }
}

resource "aws_s3_bucket_logging" "assets" {
  count = var.logging_config != null ? 1 : 0

  bucket = aws_s3_bucket.assets.bucket

  target_bucket = var.logging_config.target_bucket
  target_prefix = var.logging_config.target_prefix
}

resource "aws_s3_bucket_lifecycle_configuration" "assets" {
  depends_on = [aws_s3_bucket_versioning.assets]
  bucket     = aws_s3_bucket.assets.bucket

  rule {
    id     = "abort-failed-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }

  rule {
    id     = "clear-versioned-assets"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 60
      storage_class   = "GLACIER"
    }
  }
}

resource "aws_cloudfront_origin_access_identity" "assets" {
  comment = "CloudFront OAI for Assets S3 Bucket"
}

data "aws_iam_policy_document" "read_assets_bucket" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject*"]
    resources = ["${aws_s3_bucket.assets.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.assets.iam_arn]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.assets.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.assets.iam_arn]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resources = [aws_s3_bucket.assets.arn, "${aws_s3_bucket.assets.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [var.server_function_role_arn]
    }
  }
  statement {
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.assets.arn, "${aws_s3_bucket.assets.arn}/*"]

    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

# Static Assets
resource "aws_s3_object" "assets" {
  provider = aws.no_default_tags
  for_each = fileset(var.assets_path, "**")

  bucket        = aws_s3_bucket.assets.bucket
  key           = "assets/${each.value}"
  source        = "${var.assets_path}/${each.value}"
  source_hash   = filemd5("${var.assets_path}/${each.value}")
  cache_control = length(regexall(".*(_next).*$", each.value)) > 0 ? "public,max-age=31536000,immutable" : var.static_asset_cache_config
  content_type  = lookup(local.content_type_lookup, split(".", each.value)[length(split(".", each.value)) - 1], "text/plain")
}

# Cached Files
resource "aws_s3_object" "cache" {
  provider = aws.no_default_tags
  for_each = fileset(var.cache_path, "**")

  bucket       = aws_s3_bucket.assets.bucket
  key          = "cache/${each.value}"
  source       = "${var.cache_path}/${each.value}"
  source_hash  = filemd5("${var.cache_path}/${each.value}")
  content_type = lookup(local.content_type_lookup, split(".", each.value)[length(split(".", each.value)) - 1], "text/plain")
}
