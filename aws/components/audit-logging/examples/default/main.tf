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

# Minimal, PCI-compliant usage: creates a CloudWatch-Logs-authorised CMK, an
# encrypted log group with 365-day retention, and a least-privilege VPC Flow
# Logs delivery role. Everything else is inherited from the secure defaults.
module "audit_logging" {
  source = "../.."

  config = {
    name_prefix = "example-audit"
  }
}

output "log_group_arn" {
  value = module.audit_logging.manifest.log_group_arn
}

output "flow_log_role_arn" {
  value = module.audit_logging.manifest.flow_log_role_arn
}
