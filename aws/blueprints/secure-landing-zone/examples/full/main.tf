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

# Full usage: every capability on, including a baseline VPC, plus a single
# bring-your-own shared CMK threaded into every component that encrypts at rest
# (audit-logging, cloudtrail, cspm, findings-notification) and a hardened custom
# IAM password policy.
module "landing_zone" {
  source = "../.."

  config = {
    name_prefix = "paws-prod"

    # One shared CMK for every encrypted store in the baseline. Manage its key
    # policy centrally; the components reuse it instead of creating their own.
    kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"

    # Hardened IAM password policy (above the PCI minimums).
    enable_account_baseline = true
    password_policy = {
      minimum_length   = 16
      max_age          = 60
      reuse_prevention = 12
    }

    enable_audit_logging = true

    # Org-wide trail (this is the management account).
    enable_cloudtrail                = true
    cloudtrail_is_organization_trail = true

    # CSPM with Inspector scanning the full default set.
    enable_cspm                   = true
    cspm_inspector_resource_types = ["ECR", "EC2", "LAMBDA"]

    enable_findings_notification = true
    findings_source              = "all"

    # The landing zone owns a baseline VPC with a couple of subnets across AZs.
    enable_network = true
    vpc_cidr       = "10.50.0.0/16"
    subnets = [
      { name = "private-a", cidr_block = "10.50.10.0/24", availability_zone = "eu-central-1a" },
      { name = "private-b", cidr_block = "10.50.11.0/24", availability_zone = "eu-central-1b" },
      { name = "public-a", cidr_block = "10.50.0.0/24", availability_zone = "eu-central-1a", public = true },
    ]
  }
}

output "vpc_id" {
  value = module.landing_zone.manifest.vpc_id
}

output "cloudtrail_arn" {
  value = module.landing_zone.manifest.cloudtrail_arn
}

output "guardduty_detector_id" {
  value = module.landing_zone.manifest.guardduty_detector_id
}

output "findings_topic_arn" {
  value = module.landing_zone.manifest.findings_topic_arn
}
