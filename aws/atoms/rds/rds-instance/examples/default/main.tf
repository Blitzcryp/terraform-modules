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

# Minimal, PCI-compliant usage: encrypted at rest, Multi-AZ, deletion protection
# on, 14-day backups, IAM auth on, master password in Secrets Manager, not
# publicly accessible. Everything else inherits the secure defaults baked into
# the config object. Subnet/SG/KMS identifiers are fake placeholders for the
# example only.
module "rds_instance" {
  source = "../.."

  config = {
    identifier           = "example-postgres"
    engine               = "postgres"
    db_subnet_group_name = "example-db-subnet-group"
    vpc_security_group_ids = [
      "sg-0123456789abcdef0",
    ]
    kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "instance_arn" {
  value = module.rds_instance.manifest.arn
}

output "secret_arn" {
  value = module.rds_instance.manifest.master_user_secret_arn
}
