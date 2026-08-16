variable "aws_region" {
  type        = string
  description = "AWS region to build the AMI in."
  default     = "eu-central-1"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type used during the Packer build."
  default     = "t3.small"
}

variable "ami_name_prefix" {
  type        = string
  description = "Prefix for the resulting AMI name."
  default     = "golden-ami-al2023"
}

variable "environment" {
  type        = string
  description = "Environment tag applied to the AMI."
}

variable "root_volume_size_gb" {
  type        = number
  description = "Size in GiB of the root EBS volume."
  default     = 20
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the Packer build instance."
}

variable "subnet_id" {
  type        = string
  description = "Public subnet ID for the Packer build instance."
}

variable "script_name" {
  type        = string
  description = "Filename of the provisioner script inside modules/golden-ami/scripts/."
  default     = "install.sh"
}
