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

# Minimal usage: a GitHub Actions OIDC provider. thumbprint_list left empty
# (AWS manages thumbprints for IAM OIDC to known IdPs); audience scoped to STS.
module "iam_oidc_provider" {
  source = "../.."

  config = {
    url            = "https://token.actions.githubusercontent.com"
    client_id_list = ["sts.amazonaws.com"]

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "oidc_provider_arn" {
  value = module.iam_oidc_provider.manifest.arn
}
