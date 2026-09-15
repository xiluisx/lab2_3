output "validation_record" {
  description = "CNAME to create in Cloudflare, DNS-only. Depends only on the certificate request, so it resolves during the first targeted apply."
  value = [
    for o in aws_acm_certificate.this.domain_validation_options : {
      name  = o.resource_record_name
      type  = o.resource_record_type
      value = o.resource_record_value
    }
  ]
}

output "certificate_arn" {
  description = "ARN of the issued certificate. Reading this forces the wait on validation."
  value       = aws_acm_certificate_validation.this.certificate_arn
}
