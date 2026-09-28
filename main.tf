terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "davidpoku-terraform-state-2026"
    key            = "terraform-basics/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  alias  = "east"
  region = "us-east-1"
}

provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

resource "aws_s3_bucket" "east_bucket" {
  provider = aws.east
  bucket   = "davidpoku-east-bucket-2026"
}

resource "aws_s3_bucket" "west_bucket" {
  provider = aws.west
  bucket   = "davidpoku-west-bucket-2026"
}
