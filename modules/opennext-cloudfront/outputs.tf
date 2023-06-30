output "cloudfront_distribution" {
    value = aws_cloudfront_distribution.distribution
}

output "wafv2_web_acl" {
    value = aws_wafv2_web_acl.cloudfront_waf
}
