<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.60 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_macie_account"></a> [macie\_account](#module\_macie\_account) | ../../atoms/macie/macie-account | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the Macie component (sensitive-data discovery for S3). All<br/>inputs live on this single object. PCI-compliant defaults are baked into the<br/>optional() fields, so passing `{}` (or omitting config) ENABLES Macie with<br/>the fastest finding cadence (FIFTEEN\_MINUTES) for continuous S3<br/>sensitive-data (cardholder data) discovery — PCI DSS Req 3 / Req A.<br/><br/>NOTE: targeted classification jobs (scanning specific buckets on a schedule)<br/>are defined separately; this component owns only the account-level<br/>enablement, which is the core continuous-discovery capability. | <pre>object({<br/>    # Macie account status. ENABLED (default) turns on continuous S3<br/>    # sensitive-data discovery; PAUSED suspends it without deleting findings.<br/>    status = optional(string, "ENABLED")<br/><br/>    # How frequently Macie publishes findings.<br/>    finding_publishing_frequency = optional(string, "FIFTEEN_MINUTES")<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the Macie component, collected on a single object. |
<!-- END_TF_DOCS -->