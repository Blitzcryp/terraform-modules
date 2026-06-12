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

# Minimal, PCI-compliant usage: a secure Step Functions workflow. The component
# creates a customer-managed KMS key (encrypting the execution log group), a
# one-year-retention encrypted /aws/vendedlogs/states/<name> log group, and a
# least-privilege execution role that trusts states.amazonaws.com — all from a
# single config object. Execution logging is level ALL and X-Ray tracing is on;
# execution data is NOT logged (it may carry CHD).
#
# SECURITY: grant the workflow downstream-service permissions via
# config.additional_policy_json (a least-privilege policy you supply). The
# trivial Pass workflow below invokes nothing, so none is needed here.
module "step_function" {
  source = "../.."

  config = {
    name = "example-workflow"

    definition = jsonencode({
      Comment = "Minimal single-state workflow"
      StartAt = "Done"
      States = {
        Done = {
          Type = "Pass"
          End  = true
        }
      }
    })

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "state_machine_arn" {
  value = module.step_function.manifest.state_machine_arn
}

output "role_arn" {
  value = module.step_function.manifest.role_arn
}

output "log_group_name" {
  value = module.step_function.manifest.log_group_name
}
