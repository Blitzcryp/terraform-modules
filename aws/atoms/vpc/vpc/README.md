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
| [aws_default_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_flow_log.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the VPC. All inputs live on this single object.<br/>PCI-DSS-compliant defaults are baked into the optional() fields. Required<br/>fields (name, cidr\_block) have no default, so config cannot be omitted.<br/>Insecure choices require flipping an explicit `allow_*` escape hatch. | <pre>object({<br/>    name       = string # required — no default<br/>    cidr_block = string # required — no default<br/><br/>    instance_tenancy = optional(string, "default")<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 1 segmentation, Req 10 logging) ---<br/>    enable_dns_support        = optional(bool, true)<br/>    enable_dns_hostnames      = optional(bool, true)<br/>    enable_flow_logs          = optional(bool, true) # PCI DSS Req 10<br/>    flow_log_traffic_type     = optional(string, "ALL")<br/>    flow_log_destination_type = optional(string, "cloud-watch-logs")<br/>    flow_log_destination_arn  = optional(string) # null = none; required when enable_flow_logs<br/>    flow_log_iam_role_arn     = optional(string) # null = none; required for cloud-watch-logs delivery<br/>    tags                      = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_flow_logs_disabled = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the VPC atom, collected on a single object. |
<!-- END_TF_DOCS -->