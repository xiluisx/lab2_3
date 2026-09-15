output "vpc_id" {
  description = "ID of the lab VPC."
  value       = aws_vpc.this.id
}

output "subnet_ids" {
  description = "Public subnet IDs, one per availability zone, in the order of var.azs."
  value       = aws_subnet.public[*].id
}
