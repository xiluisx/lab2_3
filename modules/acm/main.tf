resource "aws_acm_certificate" "this" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = var.domain_name }
}

# Blocks until the certificate reaches ISSUED. Because the validation CNAME is added
# by hand in Cloudflare, this is the resource that waits for the human step.
resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn

  timeouts {
    create = "30m"
  }
}
