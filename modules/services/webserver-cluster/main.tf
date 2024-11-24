locals {
  http_port    = 80
  any_port     = 0
  any_protocol = -1
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

resource "aws_instance" "instance" {
  ami                    = "ami-00eb69d236edcfaf8"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg-instance.id]

  user_data                   = <<-EOF
              #!bin/bash
              echo "Hello Naveen!" > index.html
              nohup busybox httpd -f -p ${var.server_port} & 
              EOF
  user_data_replace_on_change = true

  tags = {
    Name = "naveen-test01-instance"
  }
}


# Security configuration for instance
resource "aws_security_group" "sg-instance" {
  name = "${var.cluster_name}-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }
}

# Launch configuration will be used by ASG
resource "aws_launch_configuration" "launch-config-asg" {
  image_id        = "ami-00eb69d236edcfaf8"
  instance_type   = var.instance_type
  security_groups = [aws_security_group.sg-instance.id]

  user_data = <<-EOF
              #!bin/bash
              echo "Hello Terraform!" > index.html
              nohup busybox httpd -f -p ${var.server_port} & 
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

# VPC details obtained from AWS
data "aws_vpc" "default" {
  default = true
}

# Subnet details obtained from AWS
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# LB Target Group for ASG
resource "aws_lb_target_group" "lb-target-group-asg" {
  name     = "test-lb-target-group-asg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Auto Scaling Group which will be used by Load Balancer
resource "aws_autoscaling_group" "asg-lb" {
  launch_configuration = aws_launch_configuration.launch-config-asg.name
  vpc_zone_identifier  = data.aws_subnets.default.ids

  target_group_arns = [aws_lb_target_group.lb-target-group-asg.arn]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }
}

# Security Group for ALB
resource "aws_security_group" "sg-application-lb" {
  name = "${var.cluster_name}-alb"

  # Allow inbound HTTP requests
  ingress {
    from_port   = local.http_port
    to_port     = local.http_port
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }

  # Allow all outbound requests
  egress {
    from_port   = local.any_port
    to_port     = local.any_port
    protocol    = local.any_protocol
    cidr_blocks = local.all_ips
  }
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.sg-application-lb.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_http_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.sg-application-lb.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}


# Load Balancer
resource "aws_lb" "application-lb" {
  name               = "test-application-lb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.sg-application-lb.id]
}

# Listener for Load Balancer
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application-lb.arn
  port              = local.http_port
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

# Listener rule for Load Balancer
resource "aws_lb_listener_rule" "lb-listener-rule-asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb-target-group-asg.arn
  }
}

# terraform {
#   backend "s3" {
#     bucket = "naveen-test01-terraform-state-file"
#     key = "stage/services/webserver-cluster/terraform.tfstate"
#     region = "us-east-2"

#     dynamodb_table = "naveen-test01-terraform-up-and-running-locks"
#     encrypt = true
#   }
# }
