resource "aws_wafv2_web_acl" "cloudfront_waf" {
  count = var.custom_waf == null ? 1 : 0

  provider = aws.global
  name     = "${var.prefix}-waf"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Core Rule Set (CRS)
  # https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-baseline.html#aws-managed-rule-groups-baseline-crs
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "NoUserAgent_HEADER"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.prefix}-WAF-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Bad Inputs Rule Set
  # https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-baseline.html#aws-managed-rule-groups-baseline-known-bad-inputs
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.prefix}-WAF-AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = false
    }
  }

  # Linux Operating System Rule Group
  # https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-use-case.html#aws-managed-rule-groups-use-case-linux-os
  rule {
    name     = "AWS-AWSManagedRulesLinuxRuleSet"
    priority = 3

    override_action {
      none {}
    }


    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.prefix}-WAF-AWSManagedRulesLinuxRuleSet"
      sampled_requests_enabled   = false
    }
  }

  # POSIX Operating System Rule Group
  # https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-use-case.html#aws-managed-rule-groups-use-case-posix-os
  rule {
    name     = "AWS-AWSManagedRulesUnixRuleSet"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesUnixRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.prefix}-WAF-AWSManagedRulesUnixRuleSet"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "${var.prefix}-WAF"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "waf_logging" {
  count = var.waf_logging_configuration == null || try(aws_wafv2_web_acl.cloudfront_waf[0], null) == null ? 0 : 1

  resource_arn            = aws_wafv2_web_acl.cloudfront_waf[0].arn
  log_destination_configs = var.waf_logging_configuration.log_destination_configs

  dynamic "logging_filter" {
    for_each = var.waf_logging_configuration.logging_filter != null ? [true] : []

    content {
      default_behavior = var.waf_logging_configuration.logging_filter.default_behavior

      dynamic "filter" {
        for_each = toset(var.waf_logging_configuration.logging_filter.filter)

        content {
          behavior    = filter.value.behavior
          requirement = filter.value.requirement

          dynamic "condition" {
            for_each = filter.value.action_condition != null ? toset(filter.value.action_condition) : []

            content {
              action_condition {
                action = condition.value.action
              }
            }
          }

          dynamic "condition" {
            for_each = filter.value.label_name_condition != null ? toset(filter.label_name_condition) : []

            content {
              label_name_condition {
                label_name = condition.value.label_name
              }
            }
          }
        }
      }
    }
  }

  dynamic "redacted_fields" {
    for_each = var.waf_logging_configuration.redacted_fields == null ? toset(var.waf_logging_configuration.redacted_fields) : []

    content {
      dynamic "method" {
        for_each = redacted_fields.value.method == true ? [true] : []

        content {}
      }

      dynamic "query_string" {
        for_each = redacted_fields.value.query_string == true ? [true] : []

        content {}
      }

      dynamic "single_header" {
        for_each = redacted_fields.value.single_header != null ? [true] : []

        content {
          name = redacted_fields.value.single_header.name
        }
      }

      dynamic "uri_path" {
        for_each = redacted_fields.value.uri_path == true ? [true] : []

        content {}
      }
    }
  }
}
