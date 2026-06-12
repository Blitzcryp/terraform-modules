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

# Minimal, PCI-compliant usage: encrypted at rest with a customer-managed CMK,
# TLS in transit + in-cluster, SASL/IAM auth, broker logs to CloudWatch.
# Subnet / SG / KMS values below are placeholders for the example only.
module "msk_cluster" {
  source = "../.."

  config = {
    cluster_name = "example-events"

    client_subnets = [
      "subnet-0aaaaaaaaaaaaaaa1",
      "subnet-0aaaaaaaaaaaaaaa2",
      "subnet-0aaaaaaaaaaaaaaa3",
    ]
    security_groups = ["sg-0aaaaaaaaaaaaaaa1"]

    kms_key_arn               = "arn:aws:kms:eu-central-1:000000000000:key/00000000-0000-0000-0000-000000000000"
    cloudwatch_log_group_name = "/aws/msk/example-events"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "cluster_arn" {
  value = module.msk_cluster.manifest.arn
}
