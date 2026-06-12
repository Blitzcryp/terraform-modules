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

# Minimal, PCI-compliant usage: confidential client with a generated secret,
# authorization-code OAuth flow only (no implicit), token revocation enabled,
# user-existence errors masked, and SRP auth (no password grant). Everything is
# inherited from the secure defaults baked into the config object.
module "user_pool_client" {
  source = "../.."

  config = {
    name         = "example-app-client"
    user_pool_id = "eu-central-1_EXAMPLE00"
    callback_urls = [
      "https://app.example.com/oauth2/callback",
    ]
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "client_id" {
  value = module.user_pool_client.manifest.client_id
}
