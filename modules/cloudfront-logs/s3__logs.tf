data "aws_canonical_user_id" "current" {}

resource "aws_s3_bucket" "logs" {
  bucket = var.log_bucket_name
}

resource "aws_s3_bucket_acl" "logs" {
bucket = aws_s3_bucket.logs.bucket

access_control_policy {
  owner {
    id = data.aws_canonical_user_id.current.id
  }

  grant {
    permission = "FULL_CONTROL"

    grantee {
      id = data.aws_canonical_user_id.current.id
      type = "CanonicalUser"
    }
  }

  # Grant CloudFront access to the S3 bucket
  # See: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html#AccessLogsBucketAndFileOwnership
  grant {
    permission = "FULL_CONTROL"

    grantee {
        id = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
        type = "CanonicalUser"
    }
  }
}
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.bucket

  rule {
    id     = "log-expiration"
    status = "Enabled"

    expiration {
      days = var.retention
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "logs_readonly_policy" {
  statement {
    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*",
    ]
  }
}