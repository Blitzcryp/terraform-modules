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

# Minimal, PCI-compliant usage: an HTTP API fronting a Lambda with the catch-all
# $default route. The component creates the CMK (authorised for CloudWatch Logs),
# the KMS-encrypted access-log group with 365-day retention, the AWS_PROXY
# integration to the Lambda, the route(s), and the $default stage with access
# logging and throttling on.
module "http_api" {
  source = "../.."

  config = {
    name = "example-http-api"
    # Fake Lambda invoke ARN for the example.
    lambda_invoke_arn = "arn:aws:apigateway:eu-central-1:lambda:path/2015-03-31/functions/arn:aws:lambda:eu-central-1:111122223333:function:example-fn/invocations"
  }
}

# APPLY-TIME NOTE: API Gateway must be granted permission to invoke the Lambda.
# This component intentionally does NOT create the aws_lambda_permission (it
# would couple the component to a function it does not own). Add one with the
# lambda/lambda-permission atom, scoped to "${execution_arn}/*/*" as source_arn:
#
#   module "invoke_permission" {
#     source = "../../atoms/lambda/lambda-permission"
#     config = {
#       function_name = "example-fn"
#       principal     = "apigateway.amazonaws.com"
#       source_arn    = "${module.http_api.manifest.execution_arn}/*/*"
#     }
#   }

output "api_endpoint" {
  value = module.http_api.manifest.api_endpoint
}

output "invoke_url" {
  value = module.http_api.manifest.invoke_url
}

output "execution_arn" {
  value = module.http_api.manifest.execution_arn
}

output "log_group_name" {
  value = module.http_api.manifest.log_group_name
}
