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

# Minimal, PCI-compliant usage: Container Insights on, Fargate-only capacity,
# encrypted ECS Exec audit logging. KMS ARN + log group name are inputs (this
# atom does not create them — dependencies flow down by reference).
module "ecs_cluster" {
  source = "../.."

  config = {
    name = "example-app"

    # Fake input ARN/name — in real usage these come from kms-key + a log group atom/module.
    kms_key_arn                    = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    execute_command_log_group_name = "/ecs/example-app/exec"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "cluster_arn" {
  value = module.ecs_cluster.manifest.arn
}
