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

# Minimal PCI-compliant usage: an SNS topic encrypted at rest with a dedicated
# CMK (created by the component) and a policy denying non-TLS publish. All
# security controls come from secure defaults.
module "sns" {
  source = "../.."

  config = {
    name = "example-events"
  }
}

output "manifest" {
  value = module.sns.manifest
}
