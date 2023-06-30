data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "archive_file" "cloudfront_logs_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.js"
  output_path = "${path.module}/lambda-function.zip"
}
