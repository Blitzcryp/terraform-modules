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
| [aws_securityhub_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account) | resource |
| [aws_securityhub_standards_subscription.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_standards_subscription) | resource |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the AWS Security Hub account enabler. All inputs live on<br/>this single object. PCI-DSS-compliant defaults are baked into the optional()<br/>fields, so passing `{}` (or omitting config entirely) enables Security Hub<br/>with consolidated control findings, auto-enabled new controls, and a<br/>subscription to the CIS AWS Foundations Benchmark and AWS Foundational<br/>Security Best Practices standards (PCI DSS Req 6/10/11 continuous posture). | <pre>object({<br/>    # Activate the two AWS-curated default standards (CIS + FSBP).<br/>    enable_default_standards = optional(bool, true)<br/><br/>    # Explicit standard ARNs to subscribe to. Defaults to null so the atom builds<br/>    # a region/partition-aware list for CIS AWS Foundations + AWS Foundational<br/>    # Security Best Practices. Pass a list to override the standards subscribed.<br/>    standards_arns = optional(list(string))<br/><br/>    # Consolidate findings across standards (SECURITY_CONTROL) vs one per<br/>    # standard (STANDARD_CONTROL). Consolidation is the AWS-recommended posture.<br/>    control_finding_generator = optional(string, "SECURITY_CONTROL")<br/><br/>    # Automatically enable new controls as AWS adds them to enabled standards.<br/>    auto_enable_controls = optional(bool, true)<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the Security Hub account atom, collected on a single object. |
<!-- END_TF_DOCS -->