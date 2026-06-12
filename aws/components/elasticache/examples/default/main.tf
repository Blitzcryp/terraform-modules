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

# Minimal PCI-compliant usage: an encrypted Redis caching tier across two private
# subnets. Encryption at rest uses a component-created KMS key (Req 3), transit
# encryption is on (Req 4), automatic failover + Multi-AZ are on, and the cache
# security group only allows the supplied app security group to reach port 6379 —
# no public ingress (Req 1).
#
# SECURITY (PCI DSS Req 8): the Redis AUTH token must come from a secrets manager,
# never a literal. The placeholder below stands in for a value resolved at apply
# time — e.g. data.aws_secretsmanager_secret_version.redis_auth.secret_string.
module "elasticache" {
  source = "../.."

  config = {
    name       = "example-redis"
    vpc_id     = "vpc-0a1b2c3d4e5f60718"
    subnet_ids = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]

    allowed_security_group_ids = ["sg-0a1b2c3d4e5f60099"]

    # Pulled from a secrets manager at the call site — NEVER hardcode.
    auth_token = "<YOUR_AUTH_TOKEN>"
  }
}

output "manifest" {
  value = module.elasticache.manifest
}
