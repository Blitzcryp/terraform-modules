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

# Minimal usage: an AWS_PROXY integration fronting a Lambda function. The api_id
# and the Lambda invoke ARN are supplied by the caller / higher layer.
module "integration" {
  source = "../.."

  config = {
    api_id          = "abcd1234ef"
    integration_uri = "arn:aws:lambda:eu-central-1:111122223333:function:example-fn"
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "integration_id" {
  value = module.integration.manifest.integration_id
}
