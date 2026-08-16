variable "environment" {
  type = string
}

variable "role_name" {
  type = string
}

variable "role_description" {
  type    = string
  default = "Role assumed by GitHub Actions via OIDC."
}

variable "allowed_repositories" {
  type = list(string)
}

variable "policies" {
  type    = list(string)
  default = []
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the existing GitHub OIDC provider."
}
