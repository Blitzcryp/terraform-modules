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

# Full usage: create the network, terminate TLS at a custom domain, and enable
# every tier (database + cache + WAF + ECR + secrets). The blueprint composes a
# secure-network, an ACM cert + HTTPS listener + alias record, an Aurora cluster
# and an ElastiCache Redis tier (both reachable only from the app SG), a WAF on
# the ALB, an ECR repo, and a secrets vault.
module "web" {
  source = "../.."

  config = {
    name_prefix     = "paws-checkout"
    container_image = "111122223333.dkr.ecr.eu-central-1.amazonaws.com/paws-checkout:latest"
    container_port  = 8080
    desired_count   = 3
    cpu             = "1024"
    memory          = "2048"
    environment = {
      LOG_LEVEL = "info"
      APP_ENV   = "prod"
    }

    # Create a secure VPC with public (ALB) + private (tasks/data) subnets.
    create_network = true
    vpc_cidr       = "10.20.0.0/16"
    subnets = [
      { name = "public-a", cidr_block = "10.20.0.0/24", availability_zone = "eu-central-1a", public = true },
      { name = "public-b", cidr_block = "10.20.1.0/24", availability_zone = "eu-central-1b", public = true },
      { name = "private-a", cidr_block = "10.20.10.0/24", availability_zone = "eu-central-1a" },
      { name = "private-b", cidr_block = "10.20.11.0/24", availability_zone = "eu-central-1b" },
    ]

    # Custom domain + TLS (ACM cert is DNS-validated in this hosted zone).
    domain_name    = "checkout.paws.example.com"
    hosted_zone_id = "Z0123456789ABCDEFGHIJ"

    # Every optional tier on.
    enable_ecr = true
    enable_waf = true

    enable_database = true
    database = {
      engine         = "aurora-postgresql"
      serverless     = false
      instance_class = "db.r6g.large"
      instance_count = 2
    }

    enable_cache = true
    cache = {
      node_type          = "cache.t4g.medium"
      num_cache_clusters = 2
    }

    enable_secrets = true
    secrets = {
      "app/api-key"    = { description = "Third-party API key for checkout" }
      "app/stripe-key" = { description = "Payment processor key" }
    }
  }
}

output "url" {
  value = module.web.manifest.url
}

output "database_endpoint" {
  value = module.web.manifest.database_endpoint
}

output "cache_endpoint" {
  value = module.web.manifest.cache_endpoint
}

output "waf_web_acl_arn" {
  value = module.web.manifest.waf_web_acl_arn
}
