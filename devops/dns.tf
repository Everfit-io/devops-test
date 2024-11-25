locals {
  site_name = "sample-app.aws.mhcp001.uk"
}

resource "aws_route53_zone" "aws_mhcp001" {
  name = "aws.mhcp001.uk"
}

output "aws_mhcp001_ns" {
  value = aws_route53_zone.aws_mhcp001.name_servers
}

resource "aws_route53_record" "devops_test_web_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.devops_test_web_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  ttl = 60

  type    = each.value.type
  zone_id = aws_route53_zone.aws_mhcp001.zone_id
  name    = each.value.name
  records = [each.value.record]
}

resource "aws_route53_record" "devops_test_web" {
  zone_id = aws_route53_zone.aws_mhcp001.zone_id
  name    = local.site_name
  type    = "A"
  alias {
    name                   = aws_alb.devops_test_web.dns_name
    zone_id                = aws_alb.devops_test_web.zone_id
    evaluate_target_health = false
  }
}
