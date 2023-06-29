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

# TODO: CKV_AWS_18: "Ensure the S3 bucket has access logging enabled"
# TODO: CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
# TODO: CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
resource "aws_s3_bucket" "static_assets" {
  bucket = "${var.prefix}-static-assets"
}

resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket = aws_s3_bucket.static_assets.bucket

  block_public_acls = true
  block_public_policy = true
}

resource "aws_s3_bucket_policy" "static_assets" {
  bucket = aws_s3_bucket.static_assets.bucket
  policy = data.aws_iam_policy_document.read_static_bucket.json
}

resource "aws_s3_bucket_versioning" "static_assets" {
  bucket = aws_s3_bucket.static_assets.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

# TODO: CKV_AWS_300: "Ensure S3 lifecycle configuration sets period for aborting failed uploads"
# TODO: CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
resource "aws_s3_bucket_lifecycle_configuration" "static_assets" {
  depends_on = [aws_s3_bucket_versioning.static_assets]
  bucket     = aws_s3_bucket.static_assets.bucket

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


resource "aws_cloudfront_origin_access_identity" "static_assets" {
  comment = "CloudFront OAI for Static Assets S3 Bucket"
}

data "aws_iam_policy_document" "read_static_bucket" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject*"]
    resources = ["${aws_s3_bucket.static_assets.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.static_assets.iam_arn]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.static_assets.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.static_assets.iam_arn]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resources = [aws_s3_bucket.static_assets.arn, "${aws_s3_bucket.static_assets.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [module.server_function.lambda_function_role_arn]
    }
  }
}

# Static Assets
resource "aws_s3_object" "static_files" {
  for_each = fileset("${abspath(var.opennext_build_path)}/assets", "**")

  bucket = aws_s3_bucket.static_assets.bucket
  key    = "assets/${each.value}"
  source = "${abspath(var.opennext_build_path)}/assets/${each.value}"
  etag   = filemd5("${abspath(var.opennext_build_path)}/assets/${each.value}")

  cache_control = length(regexall(".*(_next).*$", each.value)) > 0 ? "public,max-age=31536000,immutable" : "public,max-age=0,s-maxage=31536000,must-revalidate"

  content_type = lookup(local.content_type_lookup, split(".", each.value)[length(split(".", each.value)) - 1], "text/plain")
}

# Cached Files
resource "aws_s3_object" "cached_files" {
  for_each = fileset("${abspath(var.opennext_build_path)}/cache/", "**")

  bucket       = aws_s3_bucket.static_assets.bucket
  key          = "cache/${each.value}"
  source       = "${abspath(var.opennext_build_path)}/cache/${each.value}"
  etag         = filemd5("${abspath(var.opennext_build_path)}/cache/${each.value}")
  content_type = lookup(local.content_type_lookup, split(".", each.value)[length(split(".", each.value)) - 1], "text/plain")
}

