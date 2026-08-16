locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
  })
}

resource "aws_lb" "frontend" {
  name               = "${var.environment}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = true

  tags = merge(local.common_tags, {
    Name = "${var.environment}-lb"
  })
}

resource "aws_security_group" "lb_sg" {
  name        = "${var.environment}-frontend-lb-sg"
  description = "Allow http and https inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-frontend-lb-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.lb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv6" {
  security_group_id = aws_security_group.lb_sg.id
  cidr_ipv6         = "::/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.lb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv6" {
  security_group_id = aws_security_group.lb_sg.id
  cidr_ipv6         = "::/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.lb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.lb_sg.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_lb_listener" "frontend_https" {

  depends_on        = [module.aws-lb-tg]
  load_balancer_arn = aws_lb.frontend.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  # we dont have route53 hosted zone so setting up a pre imported certificate
  certificate_arn = var.https_listener_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = module.aws-lb-tg[var.active_ami].target_group_arn
  }
}

resource "aws_lb_listener" "frontend_http" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

module "aws-lb-tg" {

  source = "./aws-lb-tg"

  for_each = var.amis

  name                   = each.value.asg_name
  subnet_ids             = var.subnet_ids
  vpc_id                 = var.vpc_id
  lb_sg_id               = aws_security_group.lb_sg.id
  image_id               = var.golden_ami_ids[each.key]
  environment            = var.environment
  repo_url               = var.repo_url
  github_ssh_key         = var.github_ssh_key
  deploy_env             = var.environment
  alarm_email            = var.alarm_email
  lb_arn_suffix          = aws_lb.frontend.arn_suffix
  tags                   = var.tags
}
