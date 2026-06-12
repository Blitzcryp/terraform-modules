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

# Minimal usage: one daily rule with 35-day retention into an existing vault.
# Schedule and windows are inherited from the secure defaults.
module "backup_plan" {
  source = "../.."

  config = {
    name = "example-backup-plan"
    rules = [
      {
        rule_name         = "daily"
        target_vault_name = "example-backup-vault"
      }
    ]
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "plan_id" {
  value = module.backup_plan.manifest.id
}
