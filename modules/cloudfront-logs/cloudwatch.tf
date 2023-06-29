data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# TODO: CKV_AWS_158: "Ensure that Cloudwatch Log Group is encrypted by KMS"
# TODO: CKV_AWS_338: "Ensure CloudWatch log groups retains logs for at least 1 year"
resource "aws_cloudwatch_log_group" "target_log_group" {
  name              = var.log_group_name
  retention_in_days = var.retention
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