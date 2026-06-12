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

# Minimal, PCI-compliant usage: a private subnet with no auto public IP.
# vpc_id is a fake ID for illustration — a real caller passes an output of the
# vpc atom.
module "subnet" {
  source = "../.."

  config = {
    name              = "example-private-subnet"
    vpc_id            = "vpc-0123456789abcdef0"
    cidr_block        = "10.0.1.0/24"
    availability_zone = "eu-central-1a"

    tags = {
      Environment = "example"
      Tier        = "private"
    }
  }
}

output "subnet_id" {
  value = module.subnet.manifest.id
}
