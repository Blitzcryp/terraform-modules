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

# Minimal usage: a Cognito-prefix hosted-UI domain bound to a user pool. Pass
# config.certificate_arn to serve a custom domain over ACM instead.
module "user_pool_domain" {
  source = "../.."

  config = {
    domain       = "example-auth-emag"
    user_pool_id = "eu-central-1_EXAMPLE00"
  }
}

output "domain" {
  value = module.user_pool_domain.manifest.domain
}
