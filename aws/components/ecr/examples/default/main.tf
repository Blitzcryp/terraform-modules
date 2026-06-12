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

# Minimal, PCI-compliant usage: a CMK-encrypted ECR repository with scan-on-push,
# immutable tags and a lifecycle policy, plus account-level Inspector ECR
# scanning. Everything else is inherited from the secure defaults.
module "ecr" {
  source = "../.."

  config = {
    name = "example-app"
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "repository_url" {
  value = module.ecr.manifest.repository_url
}

output "kms_key_arn" {
  value = module.ecr.manifest.kms_key_arn
}

output "inspector_enabled" {
  value = module.ecr.manifest.inspector_enabled
}
