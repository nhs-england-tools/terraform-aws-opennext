data "archive_file" "cloudfront_logs_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.js"
  output_path = "${path.module}/lambda-function.zip"
}

# TODO: CKV_AWS_272: "Ensure AWS Lambda function is configured to validate code-signing" 
# TODO: CKV_AWS_116: "Ensure that AWS Lambda function is configured for a Dead Letter Queue (DLQ)"
resource "aws_lambda_function" "cloudfront_logs_function" {
  function_name = var.log_group_name

  runtime = var.lambda_runtime
  handler = "index.handler"

  timeout                        = 5
  reserved_concurrent_executions = 3

  filename         = data.archive_file.cloudfront_logs_zip.output_path
  source_code_hash = data.archive_file.cloudfront_logs_zip.output_base64sha256
  role             = aws_iam_role.cloudfront_logs_role.arn
  kms_key_arn      = var.kms_key_arn

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

# TODO: CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS"
# TODO: CKV_AWS_338: "Ensure CloudWatch log groups retains logs for at least 1 year"
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.log_group_name}"
  retention_in_days = 3
}

resource "aws_lambda_permission" "s3_bucket_invoke_function" {
  function_name = aws_lambda_function.cloudfront_logs_function.arn
  action        = "lambda:InvokeFunction"

  principal  = "s3.amazonaws.com"
  source_arn = aws_s3_bucket.logs.arn
}