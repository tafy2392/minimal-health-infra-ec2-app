variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "https_listener_certificate_arn" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}
