terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "davidpoku-terraform-state-2026"
    key            = "environments/management/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_organizations_policy" "deny_regions" {
  name        = "deny-non-approved-regions"
  description = "Denies actions outside of approved regions"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonApprovedRegions"
        Effect    = "Deny"
        NotAction = [
          "iam:*",
          "organizations:*",
          "route53:*",
          "budgets:*",
          "waf:*",
          "cloudfront:*",
          "globalaccelerator:*",
          "support:*",
          "sts:*"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = ["us-east-1", "us-west-2"]
          }
        }
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "workload_deny_regions" {
  policy_id = aws_organizations_policy.deny_regions.id
  target_id = "620759833799"
}
