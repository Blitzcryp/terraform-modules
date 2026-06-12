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

# Minimal, PCI-compliant usage: an account-scoped external-access analyzer.
# Everything else is inherited from the secure defaults.
module "iam_access_analyzer" {
  source = "../.."

  config = {
    name = "account-external-access"
    tags = {
      Environment = "example"
      Owner       = "security"
    }
  }
}

output "analyzer_arn" {
  value = module.iam_access_analyzer.manifest.analyzer_arn
}
