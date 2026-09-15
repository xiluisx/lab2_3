variable "name" {
  description = "Prefix for all resource names and tags, e.g. \"lab2\"."
  type        = string
}

variable "vpc_id" {
  description = "VPC the security groups belong to."
  type        = string
}

variable "lab_label" {
  description = "Heading shown at the top of the served page."
  type        = string
}
