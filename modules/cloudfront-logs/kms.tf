resource "aws_kms_key" "cloudwatch_logs_key" {
  count = var.cloudwatch_log_group_kms_key_arn == null ? 1 : 0

  description             = "KMS Key for ${var.log_group_name} log group"
  deletion_window_in_days = 10
  policy                  = data.aws_iam_policy_document.cloudwatch_logs_key_policy[0].json
  enable_key_rotation     = true

  tags = var.default_tags
}

data "aws_iam_policy_document" "cloudwatch_logs_key_policy" {
  count = var.cloudwatch_log_group_kms_key_arn == null ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.amazonaws.com", "delivery.logs.amazonaws.com"]
    }
  }
}
