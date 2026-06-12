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
| [aws_macie2_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/macie2_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the Amazon Macie account enabler. All inputs live on this<br/>single object. PCI-DSS-compliant defaults are baked into the optional()<br/>fields, so passing `{}` (or omitting config entirely) ENABLES Macie with the<br/>fastest finding cadence (FIFTEEN\_MINUTES) for continuous sensitive-data<br/>(cardholder data) discovery across S3 — PCI DSS Req 3 / Req A. | <pre>object({<br/>    # Macie account status. ENABLED (default) turns on continuous S3<br/>    # sensitive-data discovery; PAUSED suspends it without deleting findings.<br/>    status = optional(string, "ENABLED")<br/><br/>    # How frequently Macie publishes findings.<br/>    finding_publishing_frequency = optional(string, "FIFTEEN_MINUTES")<br/><br/>    # Kept for interface uniformity. NOTE: aws_macie2_account does not accept<br/>    # tags; this field cannot be applied to the resource and is surfaced in the<br/>    # manifest only.<br/>    tags = optional(map(string), {})<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the Amazon Macie account atom, collected on a single object. |
<!-- END_TF_DOCS -->