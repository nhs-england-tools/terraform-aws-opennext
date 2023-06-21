terraform {
  experiments = [module_variable_optional_attrs]
}

locals {
    opennext_abs_path = "${abspath(path.root)}/${var.opennext_build_path}"
}

data "archive_file" "server_zip" {
    type = "zip"
    source_dir = "${local.opennext_abs_path}/server-function/"
    output_path = "${local.opennext_abs_path}/server-function.zip"
}

module "server_function" {
    source = "./modules/nextjs-lambda"

    prefix = "${var.prefix}-nextjs-server"
    description = "Next.js Server"
    filename = data.archive_file.server_zip.output_path
    publish = true
}

data "archive_file" "image_optimization_zip" {
    type = "zip"
    source_dir = "${local.opennext_abs_path}/image-optimization-function/"
    output_path = "${local.opennext_abs_path}/image-optimization-function.zip"
}

module "image_optimization_function" {
    source = "./modules/nextjs-lambda"

    prefix = "${var.prefix}-nextjs-image-optimization"
    description = "Next.js Image Optimization"
    filename = data.archive_file.image_optimization_zip.output_path
    memory_size = 512

    environment_variables = {
        BUCKET_NAME = aws_s3_bucket.static_assets.bucket
    }

    iam_policy_statements = [{
      effect = "Allow"
      actions = ["s3:GetObject"]
      resources = [aws_s3_bucket.static_assets.arn, "${aws_s3_bucket.static_assets.arn}/*"]
    }]
}

data "archive_file" "warmer_zip" {
    type = "zip"
    source_dir = "${local.opennext_abs_path}/warmer-function/"
    output_path = "${local.opennext_abs_path}/warmer-function.zip"
}

module "warmer_function" {
    source = "./modules/nextjs-lambda"

    create_eventbridge_scheduled_rule = true
    prefix = "${var.prefix}-nextjs-warmer"
    description = "Next.js Warmer"
    filename = data.archive_file.warmer_zip.output_path
    memory_size = 128

    environment_variables = {
        FUNCTION_NAME = module.server_function.lambda_function_name,
        CONCURRENCY = 1
    }

    iam_policy_statements = [{
      effect = "Allow"
      actions = ["lambda:InvokeFunction"]
      resources = [module.server_function.lambda_function_arn]
    }]
}

module "cloudfront_logs" {
    source = "./modules/cloudfront-logs"

    log_group_name = "${var.prefix}-cloudfront-logs"
    retention = 30
    log_bucket_name = "${var.prefix}-cloudfront-logs"
    release_version = "v0.0.1-alpha.5"
}