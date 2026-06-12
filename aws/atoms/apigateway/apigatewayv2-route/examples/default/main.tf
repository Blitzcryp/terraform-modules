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

# Minimal usage: a GET /items route targeting an integration. The api_id and the
# integration id are supplied by the caller / higher layer.
module "route" {
  source = "../.."

  config = {
    api_id    = "abcd1234ef"
    route_key = "GET /items"
    target    = "integrations/xyz789"
  }
}

output "route_id" {
  value = module.route.manifest.route_id
}
