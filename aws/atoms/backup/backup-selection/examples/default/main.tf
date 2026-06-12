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

# Minimal usage: back up every resource tagged Backup=true, using an existing
# backup plan and service role.
module "backup_selection" {
  source = "../.."

  config = {
    name         = "example-selection"
    plan_id      = "00000000-0000-0000-0000-000000000000"
    iam_role_arn = "arn:aws:iam::111122223333:role/example-backup-role"
    selection_tags = [
      {
        key   = "Backup"
        value = "true"
      }
    ]
  }
}

output "selection_id" {
  value = module.backup_selection.manifest.id
}
