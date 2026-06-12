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
| [aws_lb_listener.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the load balancer listener (aws\_lb\_listener). All inputs<br/>live on this single object. PCI-DSS-compliant defaults are baked into the<br/>optional() fields: the listener terminates TLS (HTTPS) with a modern TLS1.2+<br/>policy by default. A plain-HTTP listener is only permitted via an explicit<br/>escape hatch, unless its sole purpose is to redirect to HTTPS. | <pre>object({<br/>    load_balancer_arn = string # required<br/>    port              = number # required<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 4: encrypt transmission) ---<br/>    protocol        = optional(string, "HTTPS")<br/>    certificate_arn = optional(string)                                        # required when protocol = HTTPS<br/>    ssl_policy      = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06") # TLS1.2+ floor<br/><br/>    default_action = optional(object({<br/>      type             = optional(string, "forward")<br/>      target_group_arn = optional(string)<br/>      redirect = optional(object({<br/>        port        = optional(string, "443")<br/>        protocol    = optional(string, "HTTPS")<br/>        status_code = optional(string, "HTTP_301")<br/>      }))<br/>    }), {})<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_insecure_http = optional(bool, false) # permits a non-redirect plain-HTTP listener<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the LB listener atom, collected on a single object. |
<!-- END_TF_DOCS -->