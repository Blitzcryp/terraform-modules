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
| [aws_appautoscaling_policy.cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.memory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for ECS service Application Auto Scaling. All inputs live on<br/>this single object. Wraps an aws\_appautoscaling\_target plus two<br/>target-tracking aws\_appautoscaling\_policy resources (CPU and memory).<br/><br/>Secure/sensible defaults are baked into the optional() fields: min\_capacity<br/>defaults to 2 (>1 task for availability), scalable\_dimension/service\_namespace<br/>target an ECS service's DesiredCount. The caller only supplies the required<br/>`resource_id` (e.g. "service/<cluster>/<service>"). This atom takes the<br/>resource\_id as an input and does NOT create the ECS service (dependencies<br/>flow down by reference). | <pre>object({<br/>    # resource_id is REQUIRED: identifies the scalable ECS service, in the form<br/>    # "service/<cluster-name>/<service-name>". The caller must decide it.<br/>    resource_id = string<br/><br/>    # --- Capacity bounds (min defaults to 2 for availability) ---<br/>    min_capacity = optional(number, 2)<br/>    max_capacity = optional(number, 10)<br/><br/>    scalable_dimension = optional(string, "ecs:service:DesiredCount")<br/>    service_namespace  = optional(string, "ecs")<br/><br/>    # --- Target-tracking targets (percent utilisation) ---<br/>    target_cpu    = optional(number, 60)<br/>    target_memory = optional(number, 70)<br/><br/>    scale_in_cooldown  = optional(number, 300) # slower scale-in to avoid flapping<br/>    scale_out_cooldown = optional(number, 60)  # faster scale-out for responsiveness<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the ECS app-autoscaling atom, collected on a single object. |
<!-- END_TF_DOCS -->