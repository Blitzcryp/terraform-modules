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
| [aws_cloudtrail.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the CloudTrail trail. All inputs live on this single<br/>object. PCI-DSS-compliant defaults (PCI DSS Req 10: track & monitor all<br/>access) are baked into the optional() fields, so the caller only has to<br/>supply the required `name` and `s3_bucket_name`. Insecure choices require<br/>flipping an explicit `allow_*` escape hatch.<br/><br/>NOTE: this atom does NOT create the S3 bucket, KMS key, CloudWatch log<br/>group or delivery role — those are owned by higher layers and their<br/>names/ARNs are passed in. The atom owns exactly the aws\_cloudtrail resource. | <pre>object({<br/>    # --- Required: the caller must decide these. No defaults. ---<br/>    name           = string # trail name<br/>    s3_bucket_name = string # destination log bucket (created elsewhere; taken as input)<br/><br/>    s3_key_prefix = optional(string) # null = logs at the bucket root prefix<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 10) ---<br/>    is_multi_region_trail         = optional(bool, true) # capture events in every region<br/>    enable_log_file_validation    = optional(bool, true) # tamper-evident digest files (Req 10.5)<br/>    include_global_service_events = optional(bool, true) # IAM/STS/CloudFront etc.<br/>    enable_logging                = optional(bool, true) # start delivering immediately<br/>    is_organization_trail         = optional(bool, false)<br/><br/>    # --- Encryption at rest (PCI DSS Req 3); null = unencrypted (needs hatch) ---<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Optional CloudWatch Logs delivery (real-time monitoring/alerting) ---<br/>    cloud_watch_logs_group_arn = optional(string) # must end with :* (a log-stream-scoped ARN)<br/>    cloud_watch_logs_role_arn  = optional(string)<br/><br/>    # --- Event selectors (data/management events). Free-form to match provider. ---<br/>    event_selectors = optional(any, [])<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_unencrypted             = optional(bool, false) # permit kms_key_arn = null<br/>    allow_log_validation_disabled = optional(bool, false) # permit enable_log_file_validation = false<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the CloudTrail atom, collected on a single object. |
<!-- END_TF_DOCS -->