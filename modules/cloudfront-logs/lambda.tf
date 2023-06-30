resource "aws_lambda_code_signing_config" "signing_config" {
  count = var.code_signing_config == null ? 0 : 1

  description = var.code_signing_config.description

  allowed_publishers {
    signing_profile_version_arns = var.code_signing_config.signing_profile_version_arns
  }

  dynamic "policies" {
    for_each = var.code_signing_config.untrusted_artfact_on_deployment == null ? [1] : [0]

    content {
      untrusted_artifact_on_deployment = var.code_signing_config.untrusted_artfact_on_deployment
    }
  }
}

resource "aws_lambda_function" "cloudfront_logs_function" {
  function_name = var.log_group_name

  runtime = var.lambda_runtime
  handler = "index.handler"

  timeout                        = 5
  reserved_concurrent_executions = 3

  filename                = data.archive_file.cloudfront_logs_zip.output_path
  source_code_hash        = data.archive_file.cloudfront_logs_zip.output_base64sha256
  role                    = aws_iam_role.cloudfront_logs_role.arn
  kms_key_arn             = var.kms_key_arn
  code_signing_config_arn = try(aws_lambda_code_signing_config.signing_config[0].arn, null)

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      LOG_GROUP_NAME   = var.log_group_name
      LOG_GROUP_REGION = data.aws_region.current.name
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [true] : []

    content {
      subnet_ids         = var.vpc_config.subnet_ids
      security_group_ids = var.vpc_config.security_group_ids
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_config != null ? [true] : []

    content {
      target_arn = var.dead_letter_config.target_arn
    }
  }
}

data "aws_iam_policy_document" "cloudfront_logs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudfront_logs_role" {
  name               = "${var.log_group_name}-role"
  assume_role_policy = data.aws_iam_policy_document.cloudfront_logs_assume_role.json
}

data "aws_iam_policy_document" "cloudfront_logs_policy" {
  statement {
    actions = ["s3:Get*", "s3:List*"]
    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*"
    ]
  }

  statement {
    actions   = ["logs:DescribeLogStreams"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
  }

  statement {
    actions = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [
      "${aws_cloudwatch_log_group.lambda_log_group.arn}:*",
      "${aws_cloudwatch_log_group.target_log_group.arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "cloudfront_logs_role_policy" {
  name   = "cloudwatch-logs-role-policy"
  role   = aws_iam_role.cloudfront_logs_role.name
  policy = data.aws_iam_policy_document.cloudfront_logs_policy.json
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.log_group_name}"
  retention_in_days = var.lambda_log_retention_period
  kms_key_id        = try(aws_kms_key.cloudwatch_logs_key[0].arn, var.cloudwatch_log_group_kms_key_arn)
}

resource "aws_lambda_permission" "s3_bucket_invoke_function" {
  function_name = aws_lambda_function.cloudfront_logs_function.arn
  action        = "lambda:InvokeFunction"

  principal  = "s3.amazonaws.com"
  source_arn = aws_s3_bucket.logs.arn
}
