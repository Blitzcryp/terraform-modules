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

# Minimal, PCI-compliant usage: a secure serverless function. The component
# creates a customer-managed KMS key (encrypting both env vars and logs), a
# one-year-retention encrypted log group, and a least-privilege execution role
# that trusts lambda.amazonaws.com — all from a single config object. X-Ray
# active tracing is on; the function runs on arm64.
#
# SECURITY: env vars below are non-secret configuration. Inject secrets at
# runtime from SSM / Secrets Manager, never as plaintext env vars.
module "lambda_function" {
  source = "../.."

  config = {
    name    = "example-fn"
    runtime = "python3.12"
    handler = "index.handler"

    # A real deployment package; fake path for the example.
    filename = "build/function.zip"

    environment_variables = {
      LOG_LEVEL = "INFO"
    }

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "function_arn" {
  value = module.lambda_function.manifest.function_arn
}

output "role_arn" {
  value = module.lambda_function.manifest.role_arn
}

output "log_group_name" {
  value = module.lambda_function.manifest.log_group_name
}
