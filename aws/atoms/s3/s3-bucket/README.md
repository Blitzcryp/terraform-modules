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
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the S3 bucket. All inputs live on this single object.<br/>PCI-DSS-compliant defaults are baked into the optional() fields, so passing<br/>only the required `bucket` yields a compliant bucket. Insecure choices<br/>require flipping an explicit `allow_*` escape hatch. | <pre>object({<br/>    bucket = string # required — globally unique, DNS-compliant<br/>    tags   = optional(map(string), {})<br/><br/>    # --- Encryption (PCI DSS Req 3: protect stored cardholder data) ---<br/>    enable_encryption = optional(bool, true)<br/>    kms_key_arn       = optional(string) # null = AWS-managed aws:kms key<br/><br/>    # --- Versioning (PCI DSS Req 10: protect against tampering/loss) ---<br/>    enable_versioning = optional(bool, true)<br/><br/>    # --- Public access (PCI DSS Req 1/7: restrict exposure) ---<br/>    block_public_access = optional(bool, true)<br/>    object_ownership    = optional(string, "BucketOwnerEnforced")<br/><br/>    # --- Bucket policy ---<br/>    additional_policy_statements = optional(any, [])<br/><br/>    # --- Access logging (PCI DSS Req 10: audit trails) ---<br/>    logging_target_bucket = optional(string) # null = no access logging<br/>    logging_target_prefix = optional(string, "s3-access-logs/")<br/><br/>    # --- Lifecycle ---<br/>    lifecycle_rules = optional(list(object({<br/>      id                                     = string<br/>      status                                 = optional(string, "Enabled")<br/>      prefix                                 = optional(string)<br/>      expiration_days                        = optional(number)<br/>      noncurrent_version_expiration_days     = optional(number)<br/>      abort_incomplete_multipart_upload_days = optional(number)<br/>    })), [])<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_unencrypted   = optional(bool, false)<br/>    allow_unversioned   = optional(bool, false)<br/>    allow_public_access = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the S3 bucket atom, collected on a single object. |
<!-- END_TF_DOCS -->