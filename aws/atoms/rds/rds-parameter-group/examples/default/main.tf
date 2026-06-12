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

# A DB parameter group for a standalone PostgreSQL 16 instance. Enables SSL and
# logs slow statements — both useful for PCI DSS Req 4 (encrypt in transit) and
# Req 10 (audit trails).
module "parameter_group" {
  source = "../.."

  config = {
    name   = "example-postgres16"
    family = "postgres16"

    parameters = [
      {
        name  = "rds.force_ssl"
        value = "1"
      },
      {
        name  = "log_min_duration_statement"
        value = "1000"
      },
    ]

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "parameter_group_name" {
  value = module.parameter_group.manifest.name
}
