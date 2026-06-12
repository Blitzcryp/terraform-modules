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

# Minimal, PCI-compliant usage: a STANDARD state machine with execution logging
# at level ALL wired to a CloudWatch log group and X-Ray tracing on. Execution
# data is NOT logged by default (avoids logging payloads that may contain CHD).
#
# This example wires pre-existing dependency ARNs (role + log group) because an
# atom never creates its own dependencies. See the step-function COMPONENT for
# the fully-composed, batteries-included version.
module "state_machine" {
  source = "../.."

  config = {
    name     = "example-workflow"
    role_arn = "arn:aws:iam::111122223333:role/example-sfn-role"

    # A trivial Amazon States Language definition: a single Pass state.
    definition = jsonencode({
      Comment = "Minimal example workflow"
      StartAt = "Done"
      States = {
        Done = {
          Type = "Pass"
          End  = true
        }
      }
    })

    log_destination_arn = "arn:aws:logs:eu-central-1:111122223333:log-group:/aws/vendedlogs/states/example-workflow"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "state_machine_arn" {
  value = module.state_machine.manifest.arn
}
