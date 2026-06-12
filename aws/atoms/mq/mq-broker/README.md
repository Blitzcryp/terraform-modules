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
| [aws_mq_broker.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/mq_broker) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the Amazon MQ broker. All inputs live on this single object.<br/>PCI-DSS-compliant defaults are baked into the optional() fields: private (not<br/>publicly accessible), encrypted with a customer-managed KMS key, general + audit<br/>logging on. Insecure choices require flipping an explicit `allow_*` escape hatch.<br/><br/>SECURITY: broker user passwords are sensitive. They MUST be supplied from a<br/>secrets manager (AWS Secrets Manager / SSM SecureString / tfvars sourced from a<br/>vault), never committed to source control (PCI DSS Req 8). This variable is<br/>marked sensitive so plan/apply output never echoes the passwords. | <pre>object({<br/>    broker_name = string # required<br/><br/>    # --- Engine ---<br/>    engine_type    = optional(string, "ActiveMQ")<br/>    engine_version = optional(string) # null = provider/account default for engine<br/><br/>    # --- Placement ---<br/>    host_instance_type = optional(string, "mq.m5.large")<br/>    deployment_mode    = optional(string, "ACTIVE_STANDBY_MULTI_AZ")<br/>    subnet_ids         = list(string) # required<br/>    security_groups    = list(string) # required<br/><br/>    # --- Network exposure (PCI DSS Req 1) ---<br/>    publicly_accessible = optional(bool, false) # secure default<br/>    # ESCAPE HATCH: permit publicly_accessible=true. Requires a documented exception.<br/>    allow_public = optional(bool, false)<br/><br/>    # --- Encryption at rest (PCI DSS Req 3) ---<br/>    kms_key_arn = optional(string) # customer-managed CMK; null falls back to AWS-owned<br/>    # ESCAPE HATCH: permit use of the AWS-owned key when no CMK is supplied.<br/>    allow_aws_owned_key = optional(bool, false)<br/><br/>    # --- Patching ---<br/>    auto_minor_version_upgrade = optional(bool, true)<br/><br/>    # --- Logging (PCI DSS Req 10) ---<br/>    general_logs = optional(bool, true)<br/>    audit_logs   = optional(bool, true) # only valid for ActiveMQ; guarded in main.tf<br/><br/>    # --- Broker users (PCI DSS Req 8) ---<br/>    # Passwords MUST come from a secrets manager / tfvars-from-secret, NOT source control.<br/>    users = list(object({<br/>      username       = string<br/>      password       = string # sensitive — sourced from a vault, never hardcoded<br/>      console_access = optional(bool, false)<br/>      groups         = optional(list(string), [])<br/>    }))<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the MQ broker atom, collected on a single object. |
<!-- END_TF_DOCS -->