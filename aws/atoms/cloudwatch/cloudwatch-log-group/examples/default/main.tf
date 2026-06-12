terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

# Minimal, PCI-compliant usage: KMS-encrypted at rest, 365-day retention.
module "log_group" {
  source = "../.."

  config = {
    name = "/example/app/audit"

    # In a real deployment this comes from the kms-key atom's `arn` output.
    kms_key_arn = "arn:aws:kms:eu-central-1:123456789012:key/00000000-0000-0000-0000-000000000000"

    retention_in_days = 365

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "log_group_arn" {
  value = module.log_group.manifest.arn
}
