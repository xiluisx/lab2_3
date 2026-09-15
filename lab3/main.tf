module "network" {
  source = "../modules/network"

  name       = "lab3"
  cidr_block = "10.1.0.0/16"
  azs        = var.azs
}

module "webserver" {
  source = "../modules/webserver"

  name      = "lab3"
  vpc_id    = module.network.vpc_id
  lab_label = "Lab 3 - HTTPS load balancing with EC2 Auto Scaling"
}

module "acm" {
  source = "../modules/acm"

  domain_name = var.domain_name
}

module "alb" {
  source = "../modules/alb"

  name            = "lab3"
  vpc_id          = module.network.vpc_id
  subnet_ids      = module.network.subnet_ids
  alb_sg_id       = module.webserver.alb_sg_id
  certificate_arn = module.acm.certificate_arn
}

resource "aws_launch_template" "web" {
  name_prefix   = "lab3-web-"
  image_id      = module.webserver.ami_id
  instance_type = var.instance_type
  user_data     = base64encode(module.webserver.user_data)

  vpc_security_group_ids = [module.webserver.web_sg_id]

  iam_instance_profile {
    name = var.instance_profile
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "lab3-web" }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  name                      = "lab3-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.min_size
  vpc_zone_identifier       = module.network.subnet_ids
  target_group_arns         = [module.alb.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 120

  # Pinning to latest_version rather than the literal "$Latest" means a template edit
  # shows up in terraform plan and triggers the instance refresh.
  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "lab3-web"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "lab3-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.cpu_target
  }
}
