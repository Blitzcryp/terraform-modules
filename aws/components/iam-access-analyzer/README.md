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
| <a name="module_analyzer"></a> [analyzer](#module\_analyzer) | ../../atoms/accessanalyzer/accessanalyzer-analyzer | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the IAM Access Analyzer component (external-access<br/>detection). All inputs live on this single object. The analyzer name is<br/>required; the type defaults to the account-scoped external-access analyzer.<br/>Access Analyzer continuously detects resource policies granting access to<br/>external — or, for the *\_UNUSED\_ACCESS types, unused — principals<br/>(PCI DSS Req 7).<br/><br/>NOTE: findings surface in the IAM console and, when Security Hub is enabled,<br/>are aggregated there. Routing findings to an SNS topic requires the<br/>findings-notification component; this component does not wire that. | <pre>object({<br/>    # REQUIRED: the analyzer name. The caller must decide it. No default.<br/>    name = string<br/><br/>    # Analyzer scope. ACCOUNT (default) reports external access; the<br/>    # *_UNUSED_ACCESS variants report unused access; the ORGANIZATION variants<br/>    # widen the zone of trust to the whole organization.<br/>    type = optional(string, "ACCOUNT")<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the IAM Access Analyzer component, collected on a single object. |
<!-- END_TF_DOCS -->