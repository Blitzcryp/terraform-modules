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

# Minimal, PCI-compliant usage: the three AWS managed rule groups are enabled,
# request metrics/sampling are on, default action allows, and logging is wired
# to a CloudWatch log group whose name starts with the mandatory aws-waf-logs-
# prefix. Everything else inherits the secure defaults on the config object.
module "wafv2_web_acl" {
  source = "../.."

  config = {
    name                = "example-web-acl"
    log_destination_arn = "arn:aws:logs:eu-central-1:123456789012:log-group:aws-waf-logs-example:*"
  }
}

output "web_acl_arn" {
  value = module.wafv2_web_acl.manifest.arn
}
