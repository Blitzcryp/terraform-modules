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

# Minimal usage: a public NAT gateway in a public subnet, fronted by an EIP.
# The subnet and EIP allocation are inputs (this atom creates neither).
module "nat_gateway" {
  source = "../.."

  config = {
    subnet_id     = "subnet-00000000000000000"
    allocation_id = "eipalloc-00000000000000000"
    name          = "example-nat"
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "nat_gateway_id" {
  value = module.nat_gateway.manifest.id
}
