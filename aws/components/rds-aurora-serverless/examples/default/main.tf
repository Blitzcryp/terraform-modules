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

# Minimal PCI-compliant usage: an Aurora Serverless v2 PostgreSQL cluster across
# two private subnets, scaling between 0.5 and 4 ACUs. Storage is encrypted with a
# component-created KMS key, deletion protection is on, backups are retained for
# 14 days, IAM auth is on, and the master password is managed in Secrets Manager.
# The DB security group only allows the supplied app security group to reach port
# 5432 — no public ingress.
module "rds_aurora_serverless" {
  source = "../.."

  config = {
    name       = "example-serverless"
    vpc_id     = "vpc-0a1b2c3d4e5f60718"
    subnet_ids = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]

    allowed_security_group_ids = ["sg-0a1b2c3d4e5f60099"]

    min_capacity = 0.5
    max_capacity = 8
  }
}

output "manifest" {
  value = module.rds_aurora_serverless.manifest
}
