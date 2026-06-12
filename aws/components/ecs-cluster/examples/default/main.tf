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

# Minimal, PCI-compliant usage: creates a CloudWatch-Logs-authorised CMK, an
# encrypted log group (365-day retention) for ECS Exec audit logs, and a Fargate
# ECS cluster with Container Insights on. Everything else is inherited from the
# secure defaults baked into the config object.
module "ecs_cluster" {
  source = "../.."

  config = {
    name = "example-app"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "cluster_arn" {
  value = module.ecs_cluster.manifest.cluster_arn
}

output "log_group_name" {
  value = module.ecs_cluster.manifest.log_group_name
}
