terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "davidpoku-terraform-state-2026"
    key          = "environments/management/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
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
        Sid    = "DenyNonApprovedRegions"
        Effect = "Deny"
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

resource "aws_cloudtrail" "org_trail" {
  name                          = "org-wide-trail"
  s3_bucket_name                = "davidpoku-org-cloudtrail-logs-2026"
  is_organization_trail         = true
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
}

resource "aws_guardduty_organization_admin_account" "delegate" {
  admin_account_id = "441627939155"
}
resource "aws_guardduty_detector" "main" {
  enable = true

}
resource "aws_securityhub_organization_admin_account" "main" {
  admin_account_id = "441627939155"
}

resource "aws_organizations_policy" "deny_security_control_changes" {
  name        = "DenySecurityControlChanges"
  description = "Prevent workload accounts from disabling centralized security controls"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenySecurityControlChanges"
        Effect = "Deny"

        Action = [
          "cloudtrail:StopLogging",
          "cloudtrail:DeleteTrail",
          "guardduty:DeleteDetector",
          "securityhub:DisableSecurityHub"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "workload_deny_security_control_changes" {
  policy_id = aws_organizations_policy.deny_security_control_changes.id
  target_id = "620759833799"
}
