data "aws_iam_policy_document" "ec2_assume_role" {
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
  name               = "${var.environment}-${var.name}-ec2"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
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

resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-${var.name}"
  image_id      = var.image_id
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.app.arn
  }
}

resource "aws_autoscaling_group" "app" {
  capacity_rebalance  = true
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = var.subnet_ids
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

