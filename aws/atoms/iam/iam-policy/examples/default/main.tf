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

# Minimal, PCI-compliant usage: a least-privilege managed policy (scoped
# actions and resources, not "*"/"*").
module "iam_policy" {
  source = "../.."

  config = {
    name        = "example-read-app-config"
    description = "Example least-privilege policy: read app SSM parameters"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["ssm:GetParameter"]
          Resource = ["arn:aws:ssm:eu-central-1:123456789012:parameter/example/app/*"]
        }
      ]
    })

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "policy_arn" {
  value = module.iam_policy.manifest.arn
}
