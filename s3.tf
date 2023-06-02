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


resource "aws_s3_bucket" "static_assets" {
  bucket = "${var.prefix}-static-assets"
}

resource "aws_s3_bucket_policy" "static_assets" {
  bucket = aws_s3_bucket.static_assets.bucket
  policy = data.aws_iam_policy_document.read_static_bucket.json
}

resource "aws_cloudfront_origin_access_identity" "static_assets" {
  comment = "CloudFront OAI for Static Assets S3 Bucket"
}

data "aws_iam_policy_document" "read_static_bucket" {
  statement {
    actions   = ["s3:GetObject*"]
    resources = ["${aws_s3_bucket.static_assets.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.static_assets.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.static_assets.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.static_assets.iam_arn]
    }
  }
}

# Unhashed Files
resource "aws_s3_object" "unhashed_static_files" {
  for_each = fileset("build/assets/", "*")

  bucket        = aws_s3_bucket.static_assets.bucket
  key           = each.value
  source        = "build/assets/${each.value}"
  etag          = filemd5("build/assets/${each.value}")
  cache_control = "public,max-age=0,s-maxage=31536000,must-revalidate"
  content_type  = lookup(local.content_type_lookup, split(".", each.value)[length(split(".", each.value)) - 1], "text/plain")
}

# Hashed Files
resource "aws_s3_object" "hashed_static_files" {
  for_each = fileset("build/assets/_next/", "**")

  bucket        = aws_s3_bucket.static_assets.bucket
  key           = "_next/${each.value}"
  source        = "build/assets/_next/${each.value}"
  etag          = filemd5("build/assets/_next/${each.value}")
  cache_control = "public,max-age=31536000,immutable"
  content_type  = lookup(local.content_type_lookup, split(".", each.value)[length(split(".", each.value)) - 1], "text/plain")
}

