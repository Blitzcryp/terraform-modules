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

# Minimal PCI-compliant usage: a connection-pooling proxy in front of a
# PostgreSQL DB instance. TLS is required, authentication is delegated to
# Secrets Manager + IAM (the component creates a least-privilege role that can
# read only the supplied secret), and the proxy security group only allows the
# supplied app security group to reach port 5432 — no public ingress.
module "rds_proxy" {
  source = "../.."

  config = {
    name          = "example-pg-proxy"
    vpc_id        = "vpc-0a1b2c3d4e5f60718"
    subnet_ids    = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]
    engine_family = "POSTGRESQL"
    secret_arns = [
      "arn:aws:secretsmanager:eu-central-1:111122223333:secret:example-db-creds-AbCdEf",
    ]

    target_db_instance_identifier = "example-postgres"

    allowed_security_group_ids = ["sg-0a1b2c3d4e5f60099"]
  }
}

output "manifest" {
  value = module.rds_proxy.manifest
}
