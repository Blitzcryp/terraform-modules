terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

# ---------------------------------------------------------------------------
# Global tags: defined ONCE here and applied to every resource in every composed
# component via the provider's default_tags. No module call repeats these.
# ---------------------------------------------------------------------------
locals {
  global_tags = {
    Project     = "paws"
    Environment = "prod"
    Owner       = "platform-team"
    CostCenter  = "CC-1234"
    Compliance  = "pci-dss"
    ManagedBy   = "terraform"
  }
}

provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = local.global_tags
  }
}

# Minimal usage: account security baseline with defaults. With just a
# name_prefix the blueprint turns on the IAM password policy, the central audit
# log group, a multi-region CloudTrail, the CSPM posture stack (Security Hub +
# Config + GuardDuty + Inspector) and the findings -> SNS pipeline. No VPC is
# created (a landing zone may not own networking) and each component creates its
# own compliant CMK (no shared BYO key).
module "landing_zone" {
  source = "../.."

  config = {
    name_prefix = "paws-prod"
  }
}

output "audit_log_group_name" {
  value = module.landing_zone.manifest.audit_log_group_name
}

output "findings_topic_arn" {
  value = module.landing_zone.manifest.findings_topic_arn
}

output "cloudtrail_bucket_name" {
  value = module.landing_zone.manifest.cloudtrail_bucket_name
}
