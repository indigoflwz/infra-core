terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "tf_state" {
  bucket = var.bucket_name
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = var.lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute { name = "LockID" type = "S" }
}

output "bucket_name" { value = aws_s3_bucket.tf_state.bucket }
output "lock_table"  { value = aws_dynamodb_table.tf_lock.name }
infra-core/bootstrap/variables.tf

hcl
Copy
Edit
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