output "alb_dns_name" {
  description = "Hostname to point the Cloudflare CNAME at."
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "Target group instances or the ASG attach to."
  value       = aws_lb_target_group.this.arn
}
