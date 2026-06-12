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

# Minimal, PCI-compliant usage: no public IP, circuit breaker + rollback on,
# ECS Exec off. Cluster ARN, task definition, subnets and SGs are inputs (this
# atom does not create them — dependencies flow down by reference).
module "ecs_service" {
  source = "../.."

  config = {
    name            = "example-app"
    cluster_arn     = "arn:aws:ecs:eu-central-1:111122223333:cluster/example-app"
    task_definition = "arn:aws:ecs:eu-central-1:111122223333:task-definition/example-app:1"

    # Fake private subnets + SG — in real usage from network / security-group atoms.
    subnet_ids         = ["subnet-0aaaa1111bbbb2222", "subnet-0cccc3333dddd4444"]
    security_group_ids = ["sg-0eeee5555ffff6666"]

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "service_id" {
  value = module.ecs_service.manifest.id
}
