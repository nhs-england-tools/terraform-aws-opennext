data "aws_cloudfront_origin_request_policy" "origin_request_policy" {
  name = "Managed-AllViewerExceptHostHeader"
}
