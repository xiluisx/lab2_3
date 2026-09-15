resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Public HTTP and HTTPS ingress for the load balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere, redirected to HTTPS by the listener"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-alb-sg" }
}

resource "aws_security_group" "web" {
  name        = "${var.name}-web-sg"
  description = "HTTP from the load balancer only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from the ALB security group"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All outbound, needed for dnf and the SSM endpoints"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-web-sg" }
}

# There is no aws_iam_role here. The Learner Lab denies iam:CreateRole, so both labs
# attach the pre-provisioned LabInstanceProfile by name instead.

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
