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

# Minimal PCI-compliant usage: route ALL supported security findings (Security
# Hub, Inspector, GuardDuty) to a CMK-encrypted SNS topic via EventBridge. The
# CMK, topic policy (TLS-deny + EventBridge publish) and rule/target wiring all
# come from secure defaults.
module "findings_notification" {
  source = "../.."

  config = {
    name = "emag-security"
    tags = {
      Environment = "example"
      Owner       = "security"
    }
  }
}

output "manifest" {
  value = module.findings_notification.manifest
}
