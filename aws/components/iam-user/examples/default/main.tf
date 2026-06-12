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

# Minimal, PCI-compliant usage: creates ONLY the user identity. No static access
# keys and no console password are created (PCI DSS Req 8). Add this user to a
# group via the iam-group component to grant permissions.
module "iam_user" {
  source = "../.."

  config = {
    name = "example-human-user"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "user_arn" {
  value = module.iam_user.manifest.user_arn
}
