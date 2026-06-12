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

# Minimal, PCI-compliant usage: creates a GitHub Actions OIDC provider and a
# keyless CI/CD role scoped to a single repo + branch (no static keys; Req 8).
# Everything else inherits secure defaults (1h sessions, STS audience).
module "ci_oidc" {
  source = "../.."

  config = {
    role_name = "example-github-ci-deploy"

    # Scoped subject: only the main branch of this repo may assume the role.
    subjects = ["repo:emag-group/example-service:ref:refs/heads/main"]

    # Least-privilege deploy permissions, scoped to one bucket prefix.
    inline_policies = {
      deploy-artifacts = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect   = "Allow"
            Action   = ["s3:PutObject"]
            Resource = ["arn:aws:s3:::example-artifacts/ci/*"]
          }
        ]
      })
    }

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "ci_role_arn" {
  value = module.ci_oidc.manifest.role_arn
}

output "oidc_provider_arn" {
  value = module.ci_oidc.manifest.oidc_provider_arn
}
