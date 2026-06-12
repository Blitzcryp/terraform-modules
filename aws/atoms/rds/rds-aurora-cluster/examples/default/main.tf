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

# Minimal, PCI-compliant usage: encrypted at rest, deletion protection on,
# 14-day backups, IAM auth on, master password in Secrets Manager.
# Everything else inherits the secure defaults baked into the config object.
# Subnet/SG/KMS identifiers are fake placeholders for the example only.
module "aurora" {
  source = "../.."

  config = {
    cluster_identifier   = "example-aurora-pg"
    db_subnet_group_name = "example-db-subnet-group"
    vpc_security_group_ids = [
      "sg-0123456789abcdef0",
    ]
    kms_key_arn         = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    monitoring_role_arn = "arn:aws:iam::111122223333:role/example-rds-monitoring"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "cluster_arn" {
  value = module.aurora.manifest.cluster_arn
}

output "secret_arn" {
  value = module.aurora.manifest.master_user_secret_arn
}
