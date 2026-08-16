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

variable "amis" {
  type = map(object({
    script_name = optional(string, "install.sh")
    active      = optional(bool, false)
    asg_name    = string
  }))
  description = "Map of AMI name prefix -> config. Each entry produces one AMI via for_each."
  default     = {}
}

variable "golden_ami_ids" {
  type = map(string)
}

variable "active_ami" {
  type = string
}

variable "repo_url" {
  type        = string
  description = "GitHub repository URL (without scheme), e.g. github.com/org/repo"
}

variable "github_token_ssm_param" {
  type        = string
  description = "SSM Parameter Store path holding the GitHub token (SecureString)"
}
