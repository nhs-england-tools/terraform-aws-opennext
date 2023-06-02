resource "aws_route53_record" "dns_record" {
    zone_id = var.hosted_zone_id
    name = var.domain_name
    type = "A"

    alias {
        name = aws_cloudfront_distribution.next_distribution.domain_name
        zone_id = aws_cloudfront_distribution.next_distribution.hosted_zone_id
        evaluate_target_health = false
    }
}