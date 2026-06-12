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
| [aws_vpc_endpoint.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for a single VPC endpoint. All inputs live on this single<br/>object. `vpc_id` and `service_name` are required (the caller must decide<br/>them). PCI-DSS-compliant defaults are baked into the optional() fields:<br/>the endpoint is an Interface endpoint with private DNS ON, so service<br/>traffic resolves to private addresses and stays off the public internet<br/>(PCI DSS Req 1 — network segmentation). | <pre>object({<br/>    vpc_id       = string # required — the caller must decide this<br/>    service_name = string # required — full service name, e.g. com.amazonaws.eu-central-1.s3<br/><br/>    # Interface (default) keeps traffic private via an ENI + private DNS.<br/>    # Gateway is used for S3/DynamoDB and attaches to route tables instead.<br/>    vpc_endpoint_type = optional(string, "Interface")<br/><br/>    # --- Interface-endpoint wiring -------------------------------------<br/>    subnet_ids         = optional(list(string), []) # ENIs are placed in these (private) subnets<br/>    security_group_ids = optional(list(string), []) # SGs guarding the ENIs (allow 443 from the VPC)<br/>    # Private DNS makes the public service name resolve to the endpoint's<br/>    # private addresses, so existing clients reach the service without<br/>    # touching the internet (PCI DSS Req 1 segmentation). Secure default = ON.<br/>    private_dns_enabled = optional(bool, true)<br/><br/>    # --- Gateway-endpoint wiring ---------------------------------------<br/>    route_table_ids = optional(list(string), []) # route tables that get the prefix-list route<br/><br/>    # Optional endpoint policy (null = full-access default applied by AWS).<br/>    policy = optional(string)<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the VPC endpoint atom, collected on a single object. |
<!-- END_TF_DOCS -->