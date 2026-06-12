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

# Minimal PCI-compliant usage: a private Interface endpoint for Secrets Manager.
# Private DNS is ON by default, so the standard service hostname resolves to the
# endpoint's private ENIs and traffic never leaves the VPC (PCI DSS Req 1).
module "secretsmanager_endpoint" {
  source = "../.."

  config = {
    vpc_id             = "vpc-0123456789abcdef0"
    service_name       = "com.amazonaws.eu-central-1.secretsmanager"
    subnet_ids         = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
    security_group_ids = ["sg-0123456789abcdef0"]

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "endpoint_id" {
  value = module.secretsmanager_endpoint.manifest.id
}
