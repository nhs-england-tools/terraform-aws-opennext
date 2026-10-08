data "aws_kms_key" "revalidation_queue_key" {
  count  = var.kms_key_arn != null ? 1 : 0
  key_id = var.kms_key_arn
}

resource "aws_kms_key" "revalidation_queue_key" {
  count = var.kms_key_arn == null ? 1 : 0

  description             = "${var.prefix} Revalidation SQS Queue KMS Key"
  deletion_window_in_days = 10

  policy              = data.aws_iam_policy_document.revalidation_queue_key_policy[0].json
  enable_key_rotation = true

  tags = var.default_tags
}

data "aws_iam_policy_document" "revalidation_queue_key_policy" {
  count = var.kms_key_arn == null ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:root"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com", "sqs.amazonaws.com"]
    }
  }
}
