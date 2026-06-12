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

# Minimal, PCI-compliant usage: enable Inspector v2 scanning for ECR, EC2 and
# Lambda in the current account. All values inherit the secure defaults.
module "inspector2" {
  source = "../.."

  config = {}
}

output "inspector_id" {
  value = module.inspector2.manifest.id
}
