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

# Minimal, PCI-compliant usage: scan-on-push, immutable tags, encryption at rest
# (AES256 when no KMS key given), and a lifecycle policy expiring untagged images.
module "ecr_repository" {
  source = "../.."

  config = {
    name = "platform/example-service"
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "repository_url" {
  value = module.ecr_repository.manifest.repository_url
}
