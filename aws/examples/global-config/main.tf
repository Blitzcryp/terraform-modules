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
# Global tags: defined ONCE here, applied to every resource in every module
# below via the provider's default_tags. No module call repeats these.
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

# Each module inherits global_tags automatically. Only resource-specific tags
# (if any) are passed via config.tags.
module "audit_logging" {
  source = "../../components/audit-logging"
  config = {
    name_prefix = "paws-prod"
    # no global tags here — they come from default_tags
    tags = { Service = "audit" } # instance-specific only
  }
}

module "data_bucket" {
  source = "../../components/private-encrypted-bucket"
  config = {
    bucket = "paws-prod-cardholder-data"
  }
}

output "audit_log_group_arn" {
  value = module.audit_logging.manifest.log_group_arn
}

output "bucket_arn" {
  value = module.data_bucket.manifest.bucket_arn
}
