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

# Minimal, PCI-compliant usage: creates a Backup-authorised CMK, an encrypted
# vault, a daily plan with 35-day retention, a least-privilege service role, and
# a selection that backs up every resource tagged Backup=true. Everything else is
# inherited from the secure defaults.
module "backup" {
  source = "../.."

  config = {
    name = "example-backup"
  }
}

output "vault_arn" {
  value = module.backup.manifest.vault_arn
}

output "backup_role_arn" {
  value = module.backup.manifest.backup_role_arn
}
