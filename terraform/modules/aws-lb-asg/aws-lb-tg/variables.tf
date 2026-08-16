variable "environment" {
  type = string
}

variable "name" {
  type        = string
  description = "Name of asg associated with ami"
}

variable "image_id" {
  type = string
}

variable "desired_capacity" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 1
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "memory_scale_target_percent" {
  type        = number
  description = "Target mem_used_percent at which the ASG scales out/in."
  default     = 90
}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "lb_sg_id" {
  type        = string
  description = "Security group ID of the load balancer, used to allow inbound HTTP to instances."
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

variable "deploy_env" {
  type        = string
  description = "Environment name used to select the docker-compose file"
}

variable "app_dir" {
  type        = string
  description = "Directory on the instance where the repo is cloned"
  default     = "/opt/app"
}

variable "alarm_email" {
  type        = string
  description = "Email address to receive CloudWatch alarm notifications"
}

variable "lb_arn_suffix" {
  type        = string
  description = "ARN suffix of the load balancer, used for CloudWatch alarm dimensions"
}
