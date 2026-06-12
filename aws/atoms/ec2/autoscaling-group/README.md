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
| [aws_autoscaling_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the Auto Scaling group. All inputs live on this single<br/>object. The caller supplies the required `name`, `launch_template_id`, and<br/>`vpc_zone_identifier` (the private subnets the ASG launches instances into).<br/>Sizing, health checks, and target-group attachment have sensible defaults.<br/>Tags are converted into ASG `tag {}` blocks with propagate\_at\_launch=true so<br/>launched instances inherit them (PCI DSS Req 1 traceability). | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    name                = string       # ASG name<br/>    launch_template_id  = string       # the launch template to scale from<br/>    vpc_zone_identifier = list(string) # private subnets across AZs<br/><br/>    # --- Launch template version ---<br/>    launch_template_version = optional(string, "$Latest")<br/><br/>    # --- Sizing ---<br/>    min_size         = optional(number, 2)<br/>    max_size         = optional(number, 4)<br/>    desired_capacity = optional(number, 2)<br/><br/>    # --- Health checks ---<br/>    health_check_type         = optional(string, "EC2") # "EC2" or "ELB"<br/>    health_check_grace_period = optional(number, 300)<br/><br/>    # --- Load balancer attachment ---<br/>    target_group_arns = optional(list(string), [])<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the Auto Scaling group atom, collected on a single object. |
<!-- END_TF_DOCS -->