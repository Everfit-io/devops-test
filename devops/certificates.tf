resource "aws_acm_certificate" "devops_test_web_cert" {
  domain_name       = local.site_name
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "devops_test_cert_validation" {
  certificate_arn         = aws_acm_certificate.devops_test_web_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.devops_test_web_cert_validation : record.fqdn]
}
