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

# Minimal, PCI-compliant usage: a vault encrypted with a customer-managed CMK.
# Vault Lock is off by default; enable it (compliance mode) for WORM immutability.
module "backup_vault" {
  source = "../.."

  config = {
    name        = "example-backup-vault"
    kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "vault_arn" {
  value = module.backup_vault.manifest.arn
}
