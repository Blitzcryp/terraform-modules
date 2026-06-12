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

# Minimal usage: bind an existing rule to an SNS topic destination.
module "event_target" {
  source = "../.."

  config = {
    rule = "example-securityhub-findings"
    arn  = "arn:aws:sns:eu-central-1:111122223333:example-findings"
  }
}

output "target_id" {
  value = module.event_target.manifest.target_id
}
