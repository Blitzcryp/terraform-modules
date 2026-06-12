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

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_config_bucket"></a> [config\_bucket](#module\_config\_bucket) | ../../atoms/s3/s3-bucket | n/a |
| <a name="module_config_recorder"></a> [config\_recorder](#module\_config\_recorder) | ../../atoms/config/config-recorder | n/a |
| <a name="module_config_role"></a> [config\_role](#module\_config\_role) | ../../atoms/iam/iam-role | n/a |
| <a name="module_guardduty"></a> [guardduty](#module\_guardduty) | ../../atoms/guardduty/guardduty-detector | n/a |
| <a name="module_inspector"></a> [inspector](#module\_inspector) | ../../atoms/inspector/inspector2-enabler | n/a |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../../atoms/kms/kms-key | n/a |
| <a name="module_security_hub"></a> [security\_hub](#module\_security\_hub) | ../../atoms/securityhub/securityhub-account | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the CSPM (Cloud Security Posture Management) baseline<br/>component. All inputs live on this single object. This component bundles the<br/>four AWS-native posture services — Security Hub, AWS Config, GuardDuty and<br/>Inspector v2 — plus the supporting AWS Config delivery S3 bucket, KMS CMK and<br/>IAM service role. PCI-compliant defaults are baked into the optional() fields,<br/>so the caller only has to supply `name_prefix`; every capability is on by<br/>default and individually gated by its `enable_*` flag (PCI DSS Req 6/10/11). | <pre>object({<br/>    # name_prefix is REQUIRED: base name for the Config bucket, KMS alias, IAM<br/>    # role, recorder and channel. The caller must decide it. No default.<br/>    name_prefix = string<br/><br/>    # BYO CMK: if set, no kms-key atom is created and this key encrypts the<br/>    # Config delivery bucket. Otherwise the component owns a compliant CMK.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Capability toggles (each gates the corresponding atom via count) ------<br/>    enable_security_hub = optional(bool, true)<br/>    enable_config       = optional(bool, true)<br/>    enable_guardduty    = optional(bool, true)<br/>    enable_inspector    = optional(bool, true)<br/><br/>    # Inspector v2 resource types to scan continuously (PCI DSS Req 6/11).<br/>    inspector_resource_types = optional(list(string), ["ECR", "EC2", "LAMBDA"])<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the CSPM baseline component, collected on a single object. |
<!-- END_TF_DOCS -->