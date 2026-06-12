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

# Minimal, PCI-compliant usage: HTTPS listener terminating TLS1.2+ with a
# certificate, forwarding to a target group. Everything else inherited from the
# secure defaults baked into the config object.
module "listener" {
  source = "../.."

  config = {
    load_balancer_arn = "arn:aws:elasticloadbalancing:eu-central-1:123456789012:loadbalancer/app/example/0123456789abcdef"
    port              = 443
    certificate_arn   = "arn:aws:acm:eu-central-1:123456789012:certificate/11111111-2222-3333-4444-555555555555"

    default_action = {
      type             = "forward"
      target_group_arn = "arn:aws:elasticloadbalancing:eu-central-1:123456789012:targetgroup/example/abcdef0123456789"
    }

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "listener_arn" {
  value = module.listener.manifest.arn
}
