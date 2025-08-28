variable "project" {
  type        = string
  description = "Tag prefix"
  default     = "sre-core"
}

variable "environment" {
  type        = string
  description = "env tag"
  default     = "dev"
}

variable "region" {
  type        = string
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  type        = number
  description = "How many AZs (2 recommended)"
  default     = 2
}

# NAT gateway options (cost-saving)
variable "enable_nat" {
  type        = bool
  description = "Create a single NAT Gateway for private subnets"
  default     = false
}

# Optional custom tags
variable "tags" {
  type        = map(string)
  default     = {}
}