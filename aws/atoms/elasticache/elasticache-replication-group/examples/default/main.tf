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

# SECURITY (PCI DSS Req 8): the Redis AUTH token must come from a secrets manager,
# never a literal. The placeholder below stands in for a value resolved at apply
# time — e.g. data.aws_secretsmanager_secret_version.redis_auth.secret_string.
# Encryption at rest (Req 3) and in transit (Req 4) are on by default.
module "elasticache_replication_group" {
  source = "../.."

  config = {
    replication_group_id = "example-redis"
    description          = "Example Redis replication group"
    subnet_group_name    = "example-cache"
    security_group_ids   = ["sg-0a1b2c3d4e5f60099"]

    # Pulled from a secrets manager at the call site — NEVER hardcode.
    auth_token = "<YOUR_AUTH_TOKEN>"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "primary_endpoint" {
  value = module.elasticache_replication_group.manifest.primary_endpoint_address
}
