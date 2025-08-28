terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # After bootstrap, uncomment and fill with your values:
  backend "s3" {
    bucket = "aws-lab-s3-state"
    key    = "infra-core/vpc/terraform.tfstate"
    region = "eu-central-1"
    dynamodb_table = "terraform-state-lock"
    encrypt = true
  }
}
