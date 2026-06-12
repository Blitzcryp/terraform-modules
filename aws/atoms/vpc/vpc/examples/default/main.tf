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

# Minimal, PCI-compliant usage: DNS on, default SG locked to no rules, and
# VPC Flow Logs delivered to a caller-supplied CloudWatch Log Group + IAM role.
# (The destination log group and role are created elsewhere; this atom only
# references them. Fake ARNs are used here for illustration.)
module "vpc" {
  source = "../.."

  config = {
    name       = "example-vpc"
    cidr_block = "10.0.0.0/16"

    flow_log_destination_type = "cloud-watch-logs"
    flow_log_destination_arn  = "arn:aws:logs:eu-central-1:111122223333:log-group:/vpc/flow-logs:*"
    flow_log_iam_role_arn     = "arn:aws:iam::111122223333:role/vpc-flow-logs-delivery"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "vpc_id" {
  value = module.vpc.manifest.id
}

output "default_security_group_id" {
  value = module.vpc.manifest.default_security_group_id
}
