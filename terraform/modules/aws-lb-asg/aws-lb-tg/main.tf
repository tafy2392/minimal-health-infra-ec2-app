data "aws_iam_policy_document" "app_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${var.environment}-${var.name}-app-role"
  assume_role_policy = data.aws_iam_policy_document.app_assume_role.json
}

resource "aws_iam_role_policy_attachment" "app_ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "app_cloudwatch" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.environment}-${var.name}-ec2"
  role = aws_iam_role.app.name
}

resource "aws_security_group" "app" {
  name        = "${var.environment}-${var.name}-app-sg"
  description = "Allow HTTP from LB only, all outbound"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.environment}-${var.name}-app-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_http_from_lb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = var.lb_sg_id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
}

resource "aws_vpc_security_group_egress_rule" "app_all_outbound" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-${var.name}"
  image_id      = var.image_id
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.app.arn
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.app.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-${var.name}"
      Environment = var.environment
      AsgName     = "${var.environment}-${var.name}-asg"
    }
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.environment}-${var.name}-asg"
  capacity_rebalance  = true
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = var.subnet_ids

  target_group_arns = [aws_lb_target_group.app.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${var.environment}-${var.name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/healthz"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

}

resource "aws_autoscaling_policy" "scale_on_memory" {
  name                   = "${var.environment}-${var.name}-mem-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    target_value     = var.memory_scale_target_percent
    disable_scale_in = false

    customized_metric_specification {
      metric_name = "mem_used_percent"
      namespace   = "CWAgent"
      statistic   = "Average"

      metric_dimension {
        name  = "AutoScalingGroupName"
        value = aws_autoscaling_group.app.name
      }
    }
  }
}

