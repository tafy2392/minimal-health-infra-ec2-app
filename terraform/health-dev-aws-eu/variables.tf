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
    active      = optional(bool, false)
    asg_name    = string
  }))
  description = "Map of AMI name prefix -> config. Each entry produces one AMI via for_each."
  default     = {}
}

variable "domain" {
  type = string
}

variable "github_oidc_roles" {
  type = map(object({
    role_description = string
    repositories     = list(string)
    policies         = list(string)
  }))
  description = "Map of role name -> OIDC role config. Each entry creates one IAM role."
  default     = {}
}

variable "repo_url" {
  type        = string
  description = "GitHub repository URL without scheme, e.g. github.com/org/repo"
}

variable "github_ssh_key_ssm_param" {
  type        = string
  description = "SSM Parameter Store path for the SSH deploy key used by user_data to clone the repo"
}

variable "alarm_email" {
  type        = string
  description = "Email address to receive CloudWatch alarm notifications"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources"
  default     = {}
}
