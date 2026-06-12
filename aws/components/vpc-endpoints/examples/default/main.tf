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

# Minimal PCI-compliant usage: the curated set of private endpoints for a VPC.
# Gateway endpoints (S3, DynamoDB) attach to the private route tables; Interface
# endpoints (ECR, Logs, Secrets Manager, KMS, SSM, STS, monitoring) get ENIs in
# the private subnets behind an SG that only permits 443 from the VPC CIDR.
module "vpc_endpoints" {
  source = "../.."

  config = {
    vpc_id                  = "vpc-0123456789abcdef0"
    private_subnet_ids      = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
    private_route_table_ids = ["rtb-0123456789abcdef0"]

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "manifest" {
  value = module.vpc_endpoints.manifest
}
