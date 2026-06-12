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

# Minimal, PCI-compliant usage: a $default stage with access logging wired to a
# CloudWatch log group (Req 10) and default-route throttling on. api_id and the
# log group ARN are supplied by the caller / higher layer.
module "stage" {
  source = "../.."

  config = {
    api_id                     = "abcd1234ef" # from the apigatewayv2-api atom
    access_log_destination_arn = "arn:aws:logs:eu-central-1:111122223333:log-group:/aws/apigateway/example:*"
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "invoke_url" {
  value = module.stage.manifest.invoke_url
}
