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

# Minimal, PCI-compliant usage: a REGIONAL Web ACL with the three AWS baseline
# managed rule groups, request logging to a KMS-encrypted CloudWatch log group
# (365-day retention), and a CMK authorised for CloudWatch Logs. Here it is also
# associated to an example ALB. Everything else is inherited from secure defaults.
module "waf" {
  source = "../.."

  config = {
    name = "example-waf"

    associate_resource_arns = [
      "arn:aws:elasticloadbalancing:eu-central-1:111122223333:loadbalancer/app/example-alb/0123456789abcdef",
    ]

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "web_acl_arn" {
  value = module.waf.manifest.web_acl_arn
}

output "association_ids" {
  value = module.waf.manifest.association_ids
}
