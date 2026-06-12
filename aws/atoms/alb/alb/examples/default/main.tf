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

# Minimal, PCI-compliant usage: internal (not internet-facing), invalid headers
# dropped, deletion protection on, defensive desync mitigation. Everything else
# inherited from the secure defaults baked into the config object.
module "alb" {
  source = "../.."

  config = {
    name            = "example-internal-alb"
    subnets         = ["subnet-0aa11bb22cc33dd44", "subnet-0ee55ff66aa77bb88"]
    security_groups = ["sg-0123456789abcdef0"]

    access_logs_bucket = "example-alb-access-logs"
    access_logs_prefix = "example-internal-alb"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "alb_arn" {
  value = module.alb.manifest.arn
}
