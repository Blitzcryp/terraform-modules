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

# Minimal usage: a DB subnet group spanning two private subnets in distinct AZs.
# Subnet identifiers are fake placeholders for the example only.
module "db_subnet_group" {
  source = "../.."

  config = {
    name = "example-db-subnet-group"
    subnet_ids = [
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210",
    ]
    description = "Example private DB subnet group"
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "subnet_group_name" {
  value = module.db_subnet_group.manifest.name
}
