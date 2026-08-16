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
  type    = string
  default = null
}

variable "repo_url" {
  type        = string
  description = "GitHub repository URL (without scheme), e.g. github.com/org/repo"
}

variable "github_ssh_key" {
  type        = string
  description = "SSH private key content for GitHub deploy key"
  sensitive   = true
}

variable "alarm_email" {
  type        = string
  description = "Email address to receive CloudWatch alarm notifications"
}

variable "app_secret" {
  type        = string
  description = "APP_SECRET value for the application"
  sensitive   = true
}

variable "app_virtual_host" {
  type        = string
  description = "Virtual host hostname for the application"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources"
  default     = {}
}
