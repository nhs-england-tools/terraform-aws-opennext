data "aws_route53_zone" "zone" {
  name         = local.domain_name
  private_zone = false
}
