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
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the load balancer (aws\_lb). All inputs live on this single<br/>object. PCI-DSS-compliant defaults are baked into the optional() fields, so<br/>passing only the required fields yields a compliant, non-internet-facing ALB.<br/>Insecure choices require flipping an explicit `allow_*` escape hatch. | <pre>object({<br/>    name            = string       # required<br/>    subnets         = list(string) # required<br/>    security_groups = list(string) # required<br/><br/>    load_balancer_type = optional(string, "application")<br/>    idle_timeout       = optional(number, 60)<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 1: network controls; Req 4:<br/>    #     encrypt transmission; Req 10: logging) ---<br/>    internal                   = optional(bool, true) # PCI Req 1: not internet-facing by default<br/>    drop_invalid_header_fields = optional(bool, true) # PCI Req 4: reject malformed headers<br/>    enable_deletion_protection = optional(bool, true) # guard against accidental teardown<br/>    desync_mitigation_mode     = optional(string, "defensive")<br/><br/>    # Access logging (PCI Req 10). When access_logs_bucket is set, logging is enabled.<br/>    access_logs_bucket = optional(string) # null = no S3 access logs<br/>    access_logs_prefix = optional(string)<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_internet_facing = optional(bool, false) # permits internal=false<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the ALB atom, collected on a single object. |
<!-- END_TF_DOCS -->