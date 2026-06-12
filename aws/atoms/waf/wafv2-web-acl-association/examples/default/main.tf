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

# Minimal usage: bind an existing REGIONAL Web ACL to an Application Load Balancer.
# Both ARNs are supplied by the caller (here, fake example ARNs).
module "web_acl_association" {
  source = "../.."

  config = {
    web_acl_arn  = "arn:aws:wafv2:eu-central-1:111122223333:regional/webacl/example/abcd1234-ab12-cd34-ef56-abcdef123456"
    resource_arn = "arn:aws:elasticloadbalancing:eu-central-1:111122223333:loadbalancer/app/example-alb/0123456789abcdef"
  }
}

output "association_id" {
  value = module.web_acl_association.manifest.id
}
