<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.60 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_autoscaling"></a> [autoscaling](#module\_autoscaling) | ../../atoms/ecs/app-autoscaling | n/a |
| <a name="module_ecs_service"></a> [ecs\_service](#module\_ecs\_service) | ../../atoms/ecs/ecs-service | n/a |
| <a name="module_log_group"></a> [log\_group](#module\_log\_group) | ../../atoms/cloudwatch/cloudwatch-log-group | n/a |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | ../../atoms/vpc/security-group | n/a |
| <a name="module_task_definition"></a> [task\_definition](#module\_task\_definition) | ../../atoms/ecs/ecs-task-definition | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [terraform_data.guards](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the ecs-service component (a Fargate ECS service: task<br/>definition + service + dedicated security group + encrypted app log group +<br/>target-tracking autoscaling, optionally wired to a load balancer target<br/>group). All inputs live on this single object.<br/><br/>PCI-compliant defaults are baked into the optional() fields: private<br/>networking (no public IP), deployment circuit-breaker rollback (atom<br/>default), encrypted CloudWatch logs, an SG with no public ingress, and<br/>autoscaling on between 2 and 10 tasks. Insecure choices require flipping an<br/>explicit `allow_*` escape hatch that is passed down to the underlying atoms.<br/><br/>SECURITY: inject secrets into containers via the `secrets` block in<br/>container\_definitions (Secrets Manager / SSM), never plaintext `environment`<br/>(PCI DSS Req 3 / Req 8). | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    name        = string       # service + task family + SG + log group base name<br/>    cluster_arn = string       # ARN of the ECS cluster this service runs on<br/>    vpc_id      = string       # VPC for the service security group<br/>    subnet_ids  = list(string) # private subnets for the task ENIs<br/><br/>    # JSON string describing the containers (see SECURITY note above).<br/>    container_definitions = string<br/><br/>    # --- Task sizing / runtime ---<br/>    cpu                = optional(string, "256")<br/>    memory             = optional(string, "512")<br/>    desired_count      = optional(number, 2) # >1 for availability<br/>    execution_role_arn = optional(string)<br/>    task_role_arn      = optional(string)<br/><br/>    # --- Encryption (PCI DSS Req 3) ---<br/>    kms_key_arn = optional(string) # CMK for the app log group; null is rejected unless allow_unencrypted_logs=true<br/><br/>    log_retention_days = optional(number, 365)<br/><br/>    # --- Networking (PCI DSS Req 1) ---<br/>    # No public IP on task ENIs by default — tasks stay in private subnets.<br/>    assign_public_ip = optional(bool, false)<br/><br/>    # Ingress rules for the service security group. Empty by default (no<br/>    # ingress); typically a single rule referencing the load balancer's SG.<br/>    ingress_rules = optional(list(object({<br/>      description                  = string<br/>      ip_protocol                  = string<br/>      from_port                    = optional(number)<br/>      to_port                      = optional(number)<br/>      cidr_ipv4                    = optional(string)<br/>      cidr_ipv6                    = optional(string)<br/>      referenced_security_group_id = optional(string)<br/>      prefix_list_id               = optional(string)<br/>    })), [])<br/><br/>    # --- Load balancing (optional) ---<br/>    # When target_group_arn is set the service registers with that target group;<br/>    # container_name + container_port then identify the load-balanced container.<br/>    target_group_arn = optional(string)<br/>    container_name   = optional(string)<br/>    container_port   = optional(number)<br/><br/>    # --- Autoscaling (target tracking) ---<br/>    enable_autoscaling = optional(bool, true)<br/>    min_capacity       = optional(number, 2)<br/>    max_capacity       = optional(number, 10)<br/>    target_cpu         = optional(number, 60)<br/>    target_memory      = optional(number, 70)<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    # Assign a public IP to task ENIs (exposes tasks directly to the internet).<br/>    allow_public_ip = optional(bool, false)<br/>    # Run the app log group without a CMK (passed to the log-group atom).<br/>    allow_unencrypted_logs = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the ecs-service component, collected on a single object. |
<!-- END_TF_DOCS -->