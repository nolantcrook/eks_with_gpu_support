# Certificate
resource "aws_acm_certificate" "hosted_zone_acm_certificate_hauliday" {
  domain_name               = data.aws_route53_zone.hosted_zone_hauliday.name          # Apex domain
  subject_alternative_names = ["*.${data.aws_route53_zone.hosted_zone_hauliday.name}"] # Wildcard as SAN
  validation_method         = "DNS"

  tags = {
    Name = "wildcard-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation record
resource "aws_route53_record" "cert_validation_hauliday" {
  for_each = {
    for dvo in aws_acm_certificate.hosted_zone_acm_certificate_hauliday.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.route53_zone_id_hauliday
}

# Certificate validation
resource "aws_acm_certificate_validation" "hosted_zone_acm_certificate_validation_hauliday" {
  certificate_arn         = aws_acm_certificate.hosted_zone_acm_certificate_hauliday.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_hauliday : record.fqdn]
}
