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
  type = number
  default = 1
}

variable "max_size" {
  type = number
  default = 2
}

variable "min_size" {
  type = number
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
