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

# Minimal usage: a cache subnet group spanning two private subnets.
module "elasticache_subnet_group" {
  source = "../.."

  config = {
    name       = "example-cache"
    subnet_ids = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "subnet_group_name" {
  value = module.elasticache_subnet_group.manifest.name
}
