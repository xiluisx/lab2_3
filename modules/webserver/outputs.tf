output "alb_sg_id" {
  description = "Security group for the load balancer."
  value       = aws_security_group.alb.id
}

output "web_sg_id" {
  description = "Security group for the instances."
  value       = aws_security_group.web.id
}

output "ami_id" {
  description = "Latest Amazon Linux 2023 x86_64 AMI in this region."
  value       = data.aws_ssm_parameter.al2023.value
}

output "user_data" {
  description = "Rendered cloud-init script, plain text. Base64-encode it for a launch template."
  value       = templatefile("${path.module}/user-data.sh.tftpl", { lab_label = var.lab_label })
}
