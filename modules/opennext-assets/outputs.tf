output "cloudfront_origin_access_identity" {
  value = aws_cloudfront_origin_access_identity.assets
}

output "assets_bucket" {
  value = aws_s3_bucket.assets
}
