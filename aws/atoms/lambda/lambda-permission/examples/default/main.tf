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

# Minimal usage: allow an EventBridge rule to invoke a Lambda function, scoped to
# the specific rule ARN (PCI DSS Req 7 least privilege). Fake input ARNs.
module "lambda_permission" {
  source = "../.."

  config = {
    function_name = "example-fn"
    statement_id  = "AllowEventBridgeInvoke"
    principal     = "events.amazonaws.com"
    source_arn    = "arn:aws:events:eu-central-1:111122223333:rule/example-rule"
  }
}

output "statement_id" {
  value = module.lambda_permission.manifest.statement_id
}
