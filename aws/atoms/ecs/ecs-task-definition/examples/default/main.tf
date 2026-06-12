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

# Minimal, PCI-compliant usage: awsvpc networking, Fargate compatibility.
# NOTE: the `secrets` block below sources credentials from Secrets Manager — never
# plaintext `environment` (PCI DSS Req 3/8). The execution role (input ARN) must be
# granted secretsmanager:GetSecretValue + kms:Decrypt on that secret.
module "task_definition" {
  source = "../.."

  config = {
    family = "example-app"

    # Fake input ARN — in real usage this comes from an iam-role atom/module.
    execution_role_arn = "arn:aws:iam::111122223333:role/example-app-exec"
    task_role_arn      = "arn:aws:iam::111122223333:role/example-app-task"

    container_definitions = jsonencode([
      {
        name      = "app"
        image     = "111122223333.dkr.ecr.eu-central-1.amazonaws.com/example-app:latest"
        essential = true
        # PCI DSS Req 6: immutable container filesystem (read-only root).
        readonlyRootFilesystem = true
        portMappings = [
          { containerPort = 8080, protocol = "tcp" }
        ]
        # PCI DSS Req 3/8: inject secrets from Secrets Manager, NOT plaintext env.
        secrets = [
          {
            name      = "DB_PASSWORD"
            valueFrom = "arn:aws:secretsmanager:eu-central-1:111122223333:secret:example-app/db-XXXXXX"
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = "/ecs/example-app"
            "awslogs-region"        = "eu-central-1"
            "awslogs-stream-prefix" = "app"
          }
        }
      }
    ])

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "task_definition_arn" {
  value = module.task_definition.manifest.arn
}
