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
| [aws_accessanalyzer_analyzer.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/accessanalyzer_analyzer) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the IAM Access Analyzer. All inputs live on this single<br/>object. The analyzer name is required (no sensible default for an<br/>account-level singleton); the type defaults to the PCI-compliant<br/>external-access analyzer scoped to the current ACCOUNT. Access Analyzer<br/>continuously detects resource policies that grant access to external — or,<br/>for the *\_UNUSED\_ACCESS types, unused — principals (PCI DSS Req 7). | <pre>object({<br/>    # REQUIRED: the analyzer name. The caller must decide it. No default.<br/>    name = string<br/><br/>    # Zone of trust / analyzer scope. ACCOUNT (default) reports access granted to<br/>    # principals outside the account; the UNUSED_ACCESS variants report unused<br/>    # access; the ORGANIZATION variants widen the zone of trust to the whole org.<br/>    type = optional(string, "ACCOUNT")<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the IAM Access Analyzer atom, collected on a single object. |
<!-- END_TF_DOCS -->