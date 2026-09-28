terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "davidpoku-terraform-state-2026"
    key            = "environments/security-tooling/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::441627939155:role/OrganizationAccountAccessRole"
  }
}

resource "aws_s3_bucket" "security_tooling_test" {
  bucket = "davidpoku-security-tooling-test-2026"
}
