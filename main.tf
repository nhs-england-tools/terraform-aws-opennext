terraform {

}
provider "aws" {
  alias  = "global"
  region = "us-east-1"
}

locals {
  opennext_abs_path = "${abspath(path.root)}/${var.opennext_build_path}"
}

data "archive_file" "server_zip" {
  type        = "zip"
  source_dir  = "${local.opennext_abs_path}/server-function/"
  output_path = "${local.opennext_abs_path}/server-function.zip"
}

module "server_function" {
  source = "./modules/nextjs-lambda"

  prefix      = "${var.prefix}-nextjs-server"
  description = "Next.js Server"
  filename    = data.archive_file.server_zip.output_path
  publish     = true

  environment_variables = {
    CACHE_BUCKET_NAME         = aws_s3_bucket.static_assets.bucket
    CACHE_BUCKET_KEY_PREFIX   = "cache"
    CACHE_BUCKET_REGION       = "eu-west-2"
    REVALIDATION_QUEUE_URL    = aws_sqs_queue.revalidation_queue.url
    REVALIDATION_QUEUE_REGION = "eu-west-2"
  }

  iam_policy_statements = [
    {
      effect    = "Allow"
      actions   = ["s3:GetObject", "s3:PutObject", "s3:ListObjects"]
      resources = [aws_s3_bucket.static_assets.arn, "${aws_s3_bucket.static_assets.arn}/*"]
    },
    {
      effect    = "Allow"
      actions   = ["sqs:SendMessage"]
      resources = [aws_sqs_queue.revalidation_queue.arn]
    }
  ]
}

data "archive_file" "image_optimization_zip" {
  type        = "zip"
  source_dir  = "${local.opennext_abs_path}/image-optimization-function/"
  output_path = "${local.opennext_abs_path}/image-optimization-function.zip"
}

module "image_optimization_function" {
  source = "./modules/nextjs-lambda"

  prefix      = "${var.prefix}-nextjs-image-optimization"
  description = "Next.js Image Optimization"
  filename    = data.archive_file.image_optimization_zip.output_path
  memory_size = 512

  environment_variables = {
    BUCKET_NAME       = aws_s3_bucket.static_assets.bucket,
    BUCKET_KEY_PREFIX = "assets"
  }

  iam_policy_statements = [{
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = [aws_s3_bucket.static_assets.arn, "${aws_s3_bucket.static_assets.arn}/*"]
  }]
}

data "archive_file" "revalidation_zip" {
  type        = "zip"
  source_dir  = "${local.opennext_abs_path}/revalidation-function/"
  output_path = "${local.opennext_abs_path}/revalidation-function.zip"
}

module "revalidation_function" {
  source = "./modules/nextjs-lambda"

  prefix      = "${var.prefix}-nextjs-revalidation-function"
  description = "Next.js ISR Revalidation Function"
  filename    = data.archive_file.revalidation_zip.output_path
  memory_size = 128

  iam_policy_statements = [
    {
      effect    = "Allow"
      actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
      resources = [aws_sqs_queue.revalidation_queue.arn]
    }
  ]
}

data "archive_file" "warmer_zip" {
  type        = "zip"
  source_dir  = "${local.opennext_abs_path}/warmer-function/"
  output_path = "${local.opennext_abs_path}/warmer-function.zip"
}

module "warmer_function" {
  source = "./modules/nextjs-lambda"

  create_eventbridge_scheduled_rule = true
  prefix                            = "${var.prefix}-nextjs-warmer"
  description                       = "Next.js Warmer"
  filename                          = data.archive_file.warmer_zip.output_path
  memory_size                       = 128

  environment_variables = {
    FUNCTION_NAME = module.server_function.lambda_function_name,
    CONCURRENCY   = 1
  }

  iam_policy_statements = [{
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [module.server_function.lambda_function_arn]
  }]
}

module "cloudfront_logs" {
  source = "./modules/cloudfront-logs"

  log_group_name  = "${var.prefix}-cloudfront-logs"
  retention       = 365
  log_bucket_name = "${var.prefix}-cloudfront-logs"
  release_version = "v0.0.1-alpha.5"
}