terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

# ---------------------------------------------------------------------------
# Global tags: defined ONCE here and applied to every resource in every composed
# component via the provider's default_tags. No module call repeats these.
# ---------------------------------------------------------------------------
locals {
  global_tags = {
    Project     = "paws"
    Environment = "prod"
    Owner       = "platform-team"
    CostCenter  = "CC-1234"
    Compliance  = "pci-dss"
    ManagedBy   = "terraform"
  }
}

provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = local.global_tags
  }
}

# Minimal usage: app only. Bring your own VPC + subnets and a TLS certificate
# (no custom domain, so no ACM/DNS automation), no database or cache. ECR, WAF
# and a secrets vault stay ON by default. The ALB always terminates TLS and is
# the intentional public entrypoint; tasks run privately behind it.
module "web" {
  source = "../.."

  config = {
    name_prefix     = "paws-shop"
    container_image = "111122223333.dkr.ecr.eu-central-1.amazonaws.com/paws-shop:latest"
    container_port  = 8080

    # BYO network (create_network defaults to false).
    vpc_id             = "vpc-0123456789abcdef0"
    public_subnet_ids  = ["subnet-0aaa1111bbbb2222a", "subnet-0aaa1111bbbb2222b"]
    private_subnet_ids = ["subnet-0ccc3333dddd4444a", "subnet-0ccc3333dddd4444b"]

    # BYO TLS cert (the ALB always serves HTTPS). With a custom domain you would
    # set domain_name + hosted_zone_id instead and let the blueprint issue one.
    certificate_arn = "arn:aws:acm:eu-central-1:111122223333:certificate/abcd1234-ab12-cd34-ef56-abcdef123456"

    # Non-secret config only. Secret material goes through enable_secrets.
    environment = {
      LOG_LEVEL = "info"
    }
  }
}

output "url" {
  value = module.web.manifest.url
}

output "service_name" {
  value = module.web.manifest.service_name
}
