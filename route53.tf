resource "aws_route53_record" "dns_record_a" {
  for_each = var.create_route53_records ? toset(var.aliases) : toset([])

  zone_id = var.hosted_zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.next_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.next_distribution.hosted_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}

resource "aws_route53_record" "dns_record_aaaa" {
  for_each = var.create_route53_records ? toset(var.aliases) : toset([])

  zone_id = var.hosted_zone_id
  name = each.value
  type = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.next_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.next_distribution.hosted_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}