variable "name" {
  description = "Prefix for all resource names and tags, e.g. \"lab2\"."
  type        = string
}

variable "vpc_id" {
  description = "VPC the target group belongs to."
  type        = string
}

variable "subnet_ids" {
  description = "Public subnets the load balancer is placed in. Exactly two, in different AZs."
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security group applied to the load balancer."
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener."
  type        = string
}
