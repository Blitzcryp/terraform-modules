<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.60 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_ecs_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the ECS service. All inputs live on this single object.<br/>PCI-DSS-compliant defaults are baked into the optional() fields: tasks get<br/>NO public IP, deployment circuit breaker + rollback are on, and ECS Exec<br/>(a debugging backdoor into running containers) is off. Insecure choices<br/>require flipping an explicit `allow_*` escape hatch. | <pre>object({<br/>    name               = string       # required — service name<br/>    cluster_arn        = string       # required — ARN of the ECS cluster (input)<br/>    task_definition    = string       # required — task definition ARN or family:revision<br/>    subnet_ids         = list(string) # required — subnets for the task ENIs<br/>    security_group_ids = list(string) # required — security groups for the task ENIs<br/><br/>    desired_count = optional(number, 2) # >1 for availability<br/>    launch_type   = optional(string, "FARGATE")<br/><br/>    # --- Secure-by-default controls ---<br/>    # No public IP on task ENIs — tasks stay in private subnets (PCI DSS Req 1).<br/>    assign_public_ip = optional(bool, false)<br/><br/>    # ECS Exec is an interactive shell into running containers — a debugging<br/>    # backdoor. Off by default (PCI DSS Req 7: least privilege / restrict access).<br/>    enable_execute_command = optional(bool, false)<br/><br/>    load_balancers = optional(list(object({<br/>      target_group_arn = string<br/>      container_name   = string<br/>      container_port   = number<br/>    })), [])<br/><br/>    # ECS rolling deployments with automatic rollback on failed health checks.<br/>    deployment_controller_type        = optional(string, "ECS")<br/>    health_check_grace_period_seconds = optional(number)<br/><br/>    propagate_tags = optional(string, "SERVICE")<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    # Assign a public IP to task ENIs (exposes tasks directly to the internet).<br/>    allow_public_ip = optional(bool, false)<br/>    # Enable ECS Exec interactive container access (debugging backdoor).<br/>    allow_execute_command = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the ECS service atom, collected on a single object. |
<!-- END_TF_DOCS -->