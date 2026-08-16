data "aws_acm_certificate" "lb_certificate_frontend" {
  domain      = "*.${var.domain}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}
