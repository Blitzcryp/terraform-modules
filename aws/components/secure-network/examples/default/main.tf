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

# PCI-compliant routed network: a /16 VPC with a public and a private subnet
# across two AZs. Flow logs are ON by default and self-provisioned (encrypted
# CloudWatch log group + KMS CMK + scoped delivery role). Routing is automatic:
# the public subnet triggers an internet gateway and a single NAT gateway
# (nat_gateway_mode defaults to "single"), with a public route table
# (0.0.0.0/0 -> IGW) and a private route table (0.0.0.0/0 -> NAT).
module "secure_network" {
  source = "../.."

  config = {
    name       = "example"
    cidr_block = "10.0.0.0/16"

    subnets = [
      {
        name              = "public-a"
        cidr_block        = "10.0.0.0/24"
        availability_zone = "eu-central-1a"
        public            = true
      },
      {
        name              = "private-a"
        cidr_block        = "10.0.1.0/24"
        availability_zone = "eu-central-1a"
      },
      {
        name              = "private-b"
        cidr_block        = "10.0.2.0/24"
        availability_zone = "eu-central-1b"
      },
    ]
  }
}

output "manifest" {
  value = module.secure_network.manifest
}
