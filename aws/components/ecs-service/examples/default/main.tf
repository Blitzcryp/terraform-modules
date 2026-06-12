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

# Minimal, PCI-compliant usage: a Fargate ECS service with an encrypted app log
# group, a dedicated SG with no public ingress, private networking (no public
# IP), deployment circuit-breaker rollback (atom default), and target-tracking
# autoscaling between 2 and 10 tasks. Fake input ARNs/IDs — in real usage these
# come from the ecs-cluster component, a VPC, a KMS key and IAM roles.
module "ecs_service" {
  source = "../.."

  config = {
    name        = "example-web"
    cluster_arn = "arn:aws:ecs:eu-central-1:111122223333:cluster/example-app"
    vpc_id      = "vpc-00000000000000000"
    subnet_ids  = ["subnet-00000000000000001", "subnet-00000000000000002"]
    kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"

    execution_role_arn = "arn:aws:iam::111122223333:role/example-web-exec"
    task_role_arn      = "arn:aws:iam::111122223333:role/example-web-task"

    container_definitions = jsonencode([
      {
        name      = "web"
        image     = "111122223333.dkr.ecr.eu-central-1.amazonaws.com/example-web:latest"
        essential = true
        # Read-only root filesystem hardens the container against tampering
        # (PCI DSS Req 2 / Req 6). Use mountPoints for any writable paths.
        readonlyRootFilesystem = true
        portMappings = [
          { containerPort = 8443, protocol = "tcp" }
        ]
        # Inject secrets via the `secrets` block (Secrets Manager / SSM), never
        # plaintext `environment` (PCI DSS Req 3 / Req 8).
      }
    ])

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "service_name" {
  value = module.ecs_service.manifest.service_name
}

output "security_group_id" {
  value = module.ecs_service.manifest.security_group_id
}
