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

# Minimal, PCI-compliant usage: encryption at rest via a CMK, plus the default
# topic policy denying non-TLS publish. Everything else inherits secure defaults.
module "sns_topic" {
  source = "../.."

  config = {
    name = "example-events"

    # Replace with a real CMK ARN; encryption at rest is required for PCI.
    kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "topic_arn" {
  value = module.sns_topic.manifest.arn
}
