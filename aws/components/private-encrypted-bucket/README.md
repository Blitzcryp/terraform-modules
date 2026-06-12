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
| <a name="module_bucket"></a> [bucket](#module\_bucket) | ../../atoms/s3-bucket | n/a |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../../atoms/kms-key | n/a |
| <a name="module_log_bucket"></a> [log\_bucket](#module\_log\_bucket) | ../../atoms/s3-bucket | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the private-encrypted-bucket component. All inputs live on<br/>this single object. PCI-DSS-compliant defaults are baked into the optional()<br/>fields, so passing only the required `bucket` yields a fully locked-down,<br/>SSE-KMS-encrypted, versioned, access-logged, public-access-blocked bucket.<br/><br/>This component composes atoms via module blocks: a kms-key atom (unless a<br/>`kms_key_arn` is supplied), the main s3-bucket atom, and — when access<br/>logging is enabled and no external `access_log_bucket` is given — a companion<br/>s3-bucket atom that receives the server access logs. | <pre>object({<br/>    # --- Required: the caller must decide the main bucket name. ---<br/>    bucket = string # globally unique, DNS-compliant<br/><br/>    # --- Encryption (PCI DSS Req 3) ---<br/>    # BYOK: when set, the supplied CMK is used and no kms-key atom is created.<br/>    # When null, a dedicated kms-key atom is created for this bucket.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Versioning (PCI DSS Req 10) ---<br/>    enable_versioning = optional(bool, true)<br/><br/>    # --- Access logging (PCI DSS Req 10: audit trails) ---<br/>    enable_access_logging = optional(bool, true)<br/>    # External log target name. When null AND logging enabled, a companion log<br/>    # bucket named "${bucket}-logs" is created.<br/>    access_log_bucket = optional(string)<br/>    access_log_prefix = optional(string, "s3-access-logs/")<br/><br/>    # --- Lifecycle (shape matches the s3-bucket atom's lifecycle_rules) ---<br/>    lifecycle_rules = optional(list(any), [])<br/><br/>    # --- Bucket policy ---<br/>    additional_policy_statements = optional(any, [])<br/><br/>    # --- Tagging ---<br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the private-encrypted-bucket component, collected on a single object. |
<!-- END_TF_DOCS -->