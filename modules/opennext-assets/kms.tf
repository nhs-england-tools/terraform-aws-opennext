data "aws_kms_key" "assets_key" {
    count = var.kms_key_arn != null ? 1 : 0
    key_id = var.kms_key_arn
}

resource "aws_kms_key" "assets_key" {
    count = var.kms_key_arn == null ? 1 : 0

    description = "${var.prefix} Assets S3 Bucket KMS Key"
    deletion_window_in_days = 10

    policy = data.aws_iam_policy_document.assets_key_policy[0].json
}

data "aws_iam_policy_document" "assets_key_policy" {
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
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "cloudfront.amazonaws.com"]
    }
  }
}
