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
| <a name="module_inspector"></a> [inspector](#module\_inspector) | ../../atoms/inspector/inspector2-enabler | n/a |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../../atoms/kms/kms-key | n/a |
| <a name="module_repository"></a> [repository](#module\_repository) | ../../atoms/ecr/ecr-repository | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the ecr component (a scanning-enabled, KMS-encrypted image<br/>registry). All inputs live on this single object. PCI-compliant defaults are<br/>baked into the optional() fields, so the caller only has to supply the<br/>required `name`: a repository with scan-on-push (Req 6), immutable tags<br/>(image integrity), CMK encryption at rest (Req 3) and a lifecycle policy,<br/>plus account-level Inspector ECR scanning (Req 6 & 11). | <pre>object({<br/>    name = string # required — the repository name<br/><br/>    # --- Secure-by-default controls ---<br/>    # PCI DSS Req 3: encryption at rest. BYO CMK ARN; null = this component<br/>    # creates a CMK for the repository.<br/>    kms_key_arn = optional(string)<br/>    # Lifecycle policy: expire untagged images after N days.<br/>    untagged_expiry_days = optional(number, 14)<br/>    # PCI DSS Req 6 & 11: enable Amazon Inspector ECR scanning at the account<br/>    # level. Set false to skip the inspector2-enabler atom.<br/>    enable_inspector = optional(bool, true)<br/>    # Optional resource-based repository policy JSON.<br/>    additional_repository_policy = optional(string)<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the ecr component, collected on a single object. |
<!-- END_TF_DOCS -->