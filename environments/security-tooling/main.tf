terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "davidpoku-terraform-state-2026"
    key          = "environments/security-tooling/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
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

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "davidpoku-org-cloudtrail-logs-2026"
}

resource "aws_s3_bucket_policy" "cloudtrail_logs_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

data "aws_guardduty_detector" "main" {}

resource "aws_guardduty_organization_configuration" "main" {
  detector_id                      = data.aws_guardduty_detector.main.id
  auto_enable_organization_members = "ALL"
}
resource "aws_guardduty_member" "management" {
  account_id  = "414329795655"
  detector_id = data.aws_guardduty_detector.main.id
  email       = "divided838@gmail.com"
  invite      = true

  lifecycle {
    ignore_changes = [email]
  }
}

resource "aws_guardduty_member" "workload" {
  account_id  = "620759833799"
  detector_id = data.aws_guardduty_detector.main.id
  email       = "divided508@gmail.com"
  invite      = true

  lifecycle {
    ignore_changes = [email]
  }
}
resource "aws_securityhub_account" "main" {
  enable_default_standards = false
  auto_enable_controls     = true
}
