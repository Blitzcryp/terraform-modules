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

# Minimal, PCI-compliant usage: enables Inspector v2 scanning for ECR, EC2 and
# Lambda and creates a CMK-encrypted, TLS-only findings-notification SNS topic.
# A future EventBridge rule (no atom yet) must wire Inspector findings to the
# exposed topic ARN. Everything else is inherited from the secure defaults.
module "inspector" {
  source = "../.."

  config = {
    tags = {
      Environment = "example"
      Owner       = "security"
    }
  }
}

output "notification_topic_arn" {
  value = module.inspector.manifest.notification_topic_arn
}

output "resource_types" {
  value = module.inspector.manifest.resource_types
}
