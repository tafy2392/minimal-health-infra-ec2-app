variable "environment" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources"
  default     = {}
}
