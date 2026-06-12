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

# Minimal usage: attach an internet gateway to a VPC. The vpc_id is the only
# required input (this atom takes the VPC by reference; it does not create one).
module "internet_gateway" {
  source = "../.."

  config = {
    vpc_id = "vpc-00000000000000000"
    name   = "example-igw"
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "internet_gateway_id" {
  value = module.internet_gateway.manifest.id
}
