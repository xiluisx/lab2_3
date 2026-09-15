output "validation_record" {
  description = "Add this CNAME in Cloudflare as DNS-only before the second apply."
  value       = module.acm.validation_record
}

output "alb_dns_name" {
  description = "Point the lab3 CNAME at this hostname."
  value       = module.alb.alb_dns_name
}

output "site_url" {
  value = "https://${var.domain_name}/"
}

output "asg_name" {
  value = aws_autoscaling_group.web.name
}

output "target_group_arn" {
  description = "Used to check target health during verification."
  value       = module.alb.target_group_arn
}
