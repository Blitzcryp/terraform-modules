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
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the ECS task definition. All inputs live on this single<br/>object. PCI-DSS-compliant defaults are baked into the optional() fields<br/>(awsvpc networking, Fargate compatibility).<br/><br/>SECURITY: Secrets (DB passwords, API keys, tokens) MUST be injected into<br/>containers via the `secrets` block inside `container_definitions`, sourced<br/>from AWS Secrets Manager or SSM Parameter Store — NEVER as plaintext in the<br/>`environment` block. Plaintext secrets in a task definition violate<br/>PCI DSS Req 3 (protect stored data) and Req 8 (authentication/credentials). | <pre>object({<br/>    family = string # required — task definition family name<br/><br/>    # Required JSON string describing the containers. Inject secrets via the<br/>    # `secrets` block (Secrets Manager / SSM), never plaintext `environment`<br/>    # (PCI DSS Req 3 / Req 8 — see variable description).<br/>    container_definitions = string<br/><br/>    # --- Secure / sensible defaults ---<br/>    cpu                      = optional(string, "256")<br/>    memory                   = optional(string, "512")<br/>    network_mode             = optional(string, "awsvpc")          # task-level ENI isolation<br/>    requires_compatibilities = optional(list(string), ["FARGATE"]) # managed, patched runtime<br/><br/>    # IAM roles are inputs (this atom does not create them — flow down by reference).<br/>    execution_role_arn = optional(string)<br/>    task_role_arn      = optional(string)<br/><br/>    volumes = optional(list(any), [])<br/><br/>    runtime_platform = optional(object({<br/>      operating_system_family = optional(string, "LINUX")<br/>      cpu_architecture        = optional(string, "X86_64")<br/>    }))<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the ECS task definition atom, collected on a single object. |
<!-- END_TF_DOCS -->