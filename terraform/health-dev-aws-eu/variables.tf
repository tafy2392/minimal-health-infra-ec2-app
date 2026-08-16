variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "environment" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "golden_amis" {
  type = map(object({
    script_name = optional(string, "install.sh")
  }))
  description = "Map of AMI name prefix -> config. Each entry produces one AMI via for_each."
  default     = {}
}
