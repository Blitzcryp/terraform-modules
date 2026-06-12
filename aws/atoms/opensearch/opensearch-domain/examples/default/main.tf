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

# Minimal PCI-compliant usage: encryption at rest, node-to-node encryption,
# enforced HTTPS on TLS 1.2, and fine-grained access control (IAM master user)
# are all inherited from the secure defaults baked into the config object.
module "opensearch_domain" {
  source = "../.."

  config = {
    domain_name = "example-logs"
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "domain_arn" {
  value = module.opensearch_domain.manifest.arn
}
