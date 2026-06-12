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

# Minimal usage: a public route table (default route via an internet gateway)
# associated to one subnet. The vpc_id, gateway, and subnet are all inputs.
module "route_table" {
  source = "../.."

  config = {
    vpc_id = "vpc-00000000000000000"
    name   = "example-public-rt"

    routes = [
      {
        cidr_block = "0.0.0.0/0"
        gateway_id = "igw-00000000000000000"
      },
    ]

    subnet_ids = ["subnet-00000000000000000"]

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "route_table_id" {
  value = module.route_table.manifest.route_table_id
}
