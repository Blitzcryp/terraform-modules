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

# Minimal, PCI-compliant usage: HTTPS backend protocol with an HTTPS health
# check. Everything else inherited from the secure defaults baked into config.
module "target_group" {
  source = "../.."

  config = {
    name   = "example-tg"
    port   = 443
    vpc_id = "vpc-0123456789abcdef0"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "target_group_arn" {
  value = module.target_group.manifest.arn
}
