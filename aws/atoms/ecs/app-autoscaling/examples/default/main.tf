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

# Minimal usage: target-tracking autoscaling for an ECS service, holding CPU at
# 60% and memory at 70%, between 2 and 10 tasks. resource_id is an input — in
# real usage it is "service/<cluster-name>/<service-name>" from the ECS service.
module "app_autoscaling" {
  source = "../.."

  config = {
    resource_id = "service/example-cluster/example-service"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "target_resource_id" {
  value = module.app_autoscaling.manifest.target_resource_id
}
