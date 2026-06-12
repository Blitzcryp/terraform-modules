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

# A cluster parameter group for an Aurora PostgreSQL 16 cluster. Forces SSL and
# logs slow statements — PCI DSS Req 4 (encrypt in transit) and Req 10 (audit).
module "cluster_parameter_group" {
  source = "../.."

  config = {
    name   = "example-aurora-postgresql16"
    family = "aurora-postgresql16"

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

output "cluster_parameter_group_name" {
  value = module.cluster_parameter_group.manifest.name
}
