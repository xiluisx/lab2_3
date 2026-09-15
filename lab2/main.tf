module "network" {
  source = "../modules/network"

  name       = "lab2"
  cidr_block = "10.0.0.0/16"
  azs        = var.azs
}

module "webserver" {
  source = "../modules/webserver"

  name      = "lab2"
  vpc_id    = module.network.vpc_id
  lab_label = "Lab 2 - HTTPS load balancing across two EC2 instances"
}

module "acm" {
  source = "../modules/acm"

  domain_name = var.domain_name
}

module "alb" {
  source = "../modules/alb"

  name            = "lab2"
  vpc_id          = module.network.vpc_id
  subnet_ids      = module.network.subnet_ids
  alb_sg_id       = module.webserver.alb_sg_id
  certificate_arn = module.acm.certificate_arn
}

resource "aws_instance" "web" {
  count = 2

  ami                    = module.webserver.ami_id
  instance_type          = var.instance_type
  subnet_id              = module.network.subnet_ids[count.index]
  vpc_security_group_ids = [module.webserver.web_sg_id]
  iam_instance_profile   = var.instance_profile

  # Editing the page template recreates the instances instead of silently leaving
  # the old page in place.
  user_data                   = module.webserver.user_data
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = { Name = "lab2-web-${count.index + 1}" }
}

resource "aws_lb_target_group_attachment" "web" {
  count = length(aws_instance.web)

  target_group_arn = module.alb.target_group_arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}
