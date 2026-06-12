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

# Minimal PCI-compliant usage: an SQS queue encrypted at rest with a dedicated
# CMK (created by the component), a dead-letter queue, and a policy denying
# non-TLS access. All security controls come from secure defaults.
module "sqs" {
  source = "../.."

  config = {
    name = "example-jobs"
  }
}

output "manifest" {
  value = module.sqs.manifest
}
