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

# Minimal usage: allocate a VPC-scoped Elastic IP (e.g. for a NAT gateway).
module "elastic_ip" {
  source = "../.."

  config = {
    name = "example-nat-eip"
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "allocation_id" {
  value = module.elastic_ip.manifest.allocation_id
}
