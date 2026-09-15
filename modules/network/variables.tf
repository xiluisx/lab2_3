variable "name" {
  description = "Prefix for all resource names and tags, e.g. \"lab2\"."
  type        = string
}

variable "cidr_block" {
  description = "IPv4 CIDR for the VPC. Each lab uses a distinct block so both can run at once."
  type        = string
}

variable "azs" {
  description = "Availability zones to spread public subnets across. Exactly two."
  type        = list(string)

  validation {
    condition     = length(var.azs) == 2
    error_message = "The ALB requires exactly two availability zones."
  }
}
