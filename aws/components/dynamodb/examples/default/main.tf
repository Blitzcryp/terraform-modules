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

# Minimal PCI-compliant usage: a dedicated CMK is created and used to encrypt
# the table at rest. Point-in-time recovery and deletion protection are on by
# default. All security controls come from secure defaults.
module "orders_table" {
  source = "../.."

  config = {
    name     = "orders"
    hash_key = "order_id"

    attributes = [
      { name = "order_id", type = "S" },
    ]

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "manifest" {
  value = module.orders_table.manifest
}
