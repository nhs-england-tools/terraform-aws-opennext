resource "aws_cloudwatch_log_group" "target_log_group" {
  name              = var.log_group_name
  retention_in_days = var.retention
  kms_key_id        = try(aws_kms_key.cloudwatch_logs_key[0].arn, var.cloudwatch_log_group_kms_key_arn)
}

data "aws_iam_policy_document" "target_log_group_policy" {
  statement {
    actions   = ["logs:DescribeLogStreams"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
  }

  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.target_log_group.arn}:*"]
  }
}