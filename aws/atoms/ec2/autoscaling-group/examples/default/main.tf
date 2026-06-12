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

# Minimal usage: an ASG of 2-4 instances spread across two private subnets,
# scaling from an existing launch template. Tags propagate to launched
# instances (PCI DSS Req 1 traceability).
module "autoscaling_group" {
  source = "../.."

  config = {
    name                = "example-app"
    launch_template_id  = "lt-0a1b2c3d4e5f60718"
    vpc_zone_identifier = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "manifest" {
  value = module.autoscaling_group.manifest
}
