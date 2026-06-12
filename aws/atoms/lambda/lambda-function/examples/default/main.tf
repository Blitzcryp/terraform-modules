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

# Minimal, PCI-compliant usage: an arm64 Zip Lambda with X-Ray active tracing on
# and environment variables encrypted at rest with a customer-managed KMS key.
# Fake input ARNs/IDs — in real usage these come from the iam-role and kms-key
# components (or the lambda-function component, which wires them for you).
#
# SECURITY: env vars below are non-secret configuration. Inject secrets at
# runtime from SSM / Secrets Manager, never as plaintext env vars.
module "lambda_function" {
  source = "../.."

  config = {
    function_name = "example-fn"
    role          = "arn:aws:iam::111122223333:role/example-fn-exec"
    runtime       = "python3.12"
    handler       = "index.handler"
    filename      = "build/function.zip"

    environment_variables = {
      LOG_LEVEL = "INFO"
    }
    kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "function_arn" {
  value = module.lambda_function.manifest.arn
}

output "invoke_arn" {
  value = module.lambda_function.manifest.invoke_arn
}
