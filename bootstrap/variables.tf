variable "region" {
  type        = string
  description = "Region for state bucket & lock table"
  default     = "eu-central-1"
}

variable "bucket_name" {
  type        = string
  description = "Globally-unique S3 bucket name for Terraform state"
}

variable "lock_table" {
  type        = string
  description = "DynamoDB table name for Terraform state lock"
  default     = "terraform-state-lock"
}
