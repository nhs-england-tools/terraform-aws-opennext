# TODO: CKV_AWS_192: "Ensure WAF prevents message lookup in Log4j2. See CVE-2021-44228 aka log4jshell"
# TODO: CKV2_AWS_31: "Ensure WAF2 has a Logging Configuration"
resource "aws_wafv2_web_acl" "cloudfront_waf" {
  provider = aws.global
  name     = "${var.prefix}-nextjs-waf"
  scope    = "CLOUDFRONT"

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