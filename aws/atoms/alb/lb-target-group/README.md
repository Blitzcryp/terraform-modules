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
| [aws_lb_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the load balancer target group (aws\_lb\_target\_group). All<br/>inputs live on this single object. PCI-DSS-compliant defaults are baked into<br/>the optional() fields, so passing only the required fields yields a target<br/>group that expects encrypted (HTTPS) traffic by default. | <pre>object({<br/>    name   = string # required<br/>    port   = number # required<br/>    vpc_id = string # required<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 4: encrypt transmission) ---<br/>    protocol = optional(string, "HTTPS") # default to encrypted backend traffic<br/><br/>    target_type          = optional(string, "ip")<br/>    deregistration_delay = optional(number, 300)<br/><br/>    # Health check expects HTTPS by default to match the secure protocol default.<br/>    health_check = optional(object({<br/>      path                = optional(string, "/")<br/>      port                = optional(string, "traffic-port")<br/>      protocol            = optional(string, "HTTPS")<br/>      matcher             = optional(string, "200")<br/>      interval            = optional(number, 30)<br/>      timeout             = optional(number, 5)<br/>      healthy_threshold   = optional(number, 3)<br/>      unhealthy_threshold = optional(number, 3)<br/>    }), {})<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the LB target group atom, collected on a single object. |
<!-- END_TF_DOCS -->