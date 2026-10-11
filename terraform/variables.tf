variable "aws_region" {
  description = "AWS region for the Trend DevOps project"
  type        = string
  default     = "ap-south-1"
}

variable "admin_cidr" {
  description = "Your public IPv4 address in CIDR notation, for example 203.0.113.10/32"
  type        = string

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0))
    error_message = "Enter a valid IPv4 CIDR range, such as your-public-IP/32."
  }
}
