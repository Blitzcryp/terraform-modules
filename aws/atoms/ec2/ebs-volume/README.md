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
| [aws_ebs_volume.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the standalone EBS volume. All inputs live on this single<br/>object. PCI-DSS-compliant defaults are baked into the optional() fields: the<br/>volume is encrypted at rest (PCI Req 3) on a gp3 disk. Disabling encryption<br/>requires flipping the explicit `allow_unencrypted` escape hatch. | <pre>object({<br/>    # --- Required: the caller must decide this ---<br/>    availability_zone = string # AZ the volume is created in<br/><br/>    # --- Volume shape ---<br/>    size       = optional(number, 20)<br/>    type       = optional(string, "gp3")<br/>    iops       = optional(number) # required/allowed for io1/io2/gp3<br/>    throughput = optional(number) # gp3 only (MiB/s)<br/><br/>    # --- Encryption at rest (PCI DSS Req 3) ---<br/>    encrypted   = optional(bool, true)<br/>    kms_key_arn = optional(string) # CMK; null = AWS-managed EBS key<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_unencrypted = optional(bool, false) # permit encrypted=false<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the EBS volume atom, collected on a single object. |
<!-- END_TF_DOCS -->