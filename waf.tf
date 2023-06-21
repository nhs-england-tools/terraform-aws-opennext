resource "aws_wafv2_web_acl" "cloudfront_waf" {
  name        = "${var.prefix}-nextjs-waf"
  scope       = "GLOBAL"

  default_action {
    allow {}
  }

  rule {
    name     = "rule-1"
    priority = 1

    override_action {
      count {}
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

    token_domains = [var.domain_name]

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${var.prefix}-cloudfront-common-rule-set"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "${var.prefix}-waf"
    sampled_requests_enabled   = false
  }
}