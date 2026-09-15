variable "region" {
  description = "AWS region. The Learner Lab only permits us-east-1."
  type        = string
  default     = "us-east-1"
}

variable "profile" {
  description = "AWS CLI profile. The Learner Lab credentials live under \"academy\"."
  type        = string
  default     = "academy"
}

variable "azs" {
  description = "Availability zones for the two public subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  description = "EC2 instance type. The Learner Lab restricts this; t3.micro is permitted."
  type        = string
  default     = "t3.micro"
}

variable "instance_profile" {
  description = "Pre-provisioned Learner Lab instance profile granting SSM access."
  type        = string
  default     = "LabInstanceProfile"
}

variable "domain_name" {
  description = "Public hostname served by this lab."
  type        = string
  default     = "lab3.luisv.dev"
}

variable "min_size" {
  description = "Minimum instances in the group."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum instances the group may scale out to."
  type        = number
  default     = 6
}

variable "cpu_target" {
  description = "Average CPU percentage the target tracking policy holds."
  type        = number
  default     = 50
}
