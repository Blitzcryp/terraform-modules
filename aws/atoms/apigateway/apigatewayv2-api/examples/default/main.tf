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

# Minimal usage: an HTTP API. The default execute-api endpoint stays enabled
# here; set disable_execute_api_endpoint=true when fronting with a custom domain.
module "api" {
  source = "../.."

  config = {
    name = "example-http-api"
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "api_id" {
  value = module.api.manifest.id
}

output "api_endpoint" {
  value = module.api.manifest.api_endpoint
}
