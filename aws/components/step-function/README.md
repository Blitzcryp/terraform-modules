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
| <a name="module_exec_role"></a> [exec\_role](#module\_exec\_role) | ../../atoms/iam/iam-role | n/a |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../../atoms/kms/kms-key | n/a |
| <a name="module_log_group"></a> [log\_group](#module\_log\_group) | ../../atoms/cloudwatch/cloudwatch-log-group | n/a |
| <a name="module_state_machine"></a> [state\_machine](#module\_state\_machine) | ../../atoms/sfn/sfn-state-machine | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the step-function component (a secure Step Functions<br/>workflow: execution IAM role + encrypted CloudWatch log group + customer-<br/>managed KMS key (created unless a BYO key is supplied) + the state machine<br/>itself). All inputs live on this single object.<br/><br/>PCI-compliant defaults are baked into the optional() fields: execution<br/>logging defaults to level ALL and X-Ray active tracing is on (Req 10), the<br/>log group is encrypted at rest with a CMK and retained for one year<br/>(Req 3 / Req 10.5/10.7), and the execution role is least-privilege<br/>(CloudWatch Logs delivery + X-Ray only).<br/><br/>SECURITY: execution data is NOT logged by default (include\_execution\_data=<br/>false). Step Functions execution input/output may carry cardholder data<br/>(CHD); only enable include\_execution\_data for workflows you have confirmed<br/>never carry sensitive payloads (PCI DSS Req 3).<br/><br/>The execution role only knows how to log and trace. Grant the role the<br/>permissions the workflow needs to invoke downstream services (Lambda, SNS,<br/>ECS, etc.) via config.additional\_policy\_json — a least-privilege policy you<br/>supply (PCI DSS Req 7). | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    name       = string # state machine + role + log group base name<br/>    definition = string # Amazon States Language (ASL) JSON definition<br/><br/>    type = optional(string, "STANDARD") # STANDARD | EXPRESS<br/><br/>    # --- Encryption (PCI DSS Req 3) ---<br/>    # BYO CMK encrypting the execution log group. When null this component<br/>    # creates a CMK whose key policy authorises CloudWatch Logs in this region.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Observability (PCI DSS Req 10) ---<br/>    log_level              = optional(string, "ALL") # ALL | ERROR | FATAL | OFF<br/>    include_execution_data = optional(bool, false)   # PCI DSS Req 3: avoid logging CHD payloads<br/>    log_retention_days     = optional(number, 365)<br/><br/>    # --- Authorisation (PCI DSS Req 7) ---<br/>    # Least-privilege policy JSON granting the workflow the permissions it needs<br/>    # to invoke downstream services. Attached to the execution role alongside the<br/>    # built-in CloudWatch Logs + X-Ray policy.<br/>    additional_policy_json = optional(string)<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the step-function component, collected on a single object. |
<!-- END_TF_DOCS -->