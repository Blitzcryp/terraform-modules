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
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../../atoms/kms/kms-key | n/a |
| <a name="module_mq_broker"></a> [mq\_broker](#module\_mq\_broker) | ../../atoms/mq/mq-broker | n/a |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | ../../atoms/vpc/security-group | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the mq (Amazon MQ) component. All inputs live on this<br/>single object. PCI-DSS-compliant defaults are baked into the optional()<br/>fields, so the caller only has to supply the required `broker_name`,<br/>`vpc_id`, `subnet_ids` and `users`. The component composes a private broker<br/>security group, a customer-managed CMK (unless a BYO key is supplied), and an<br/>Amazon MQ broker that is NOT publicly accessible, encrypted with the CMK at<br/>rest, with general + audit logging on.<br/><br/>SECURITY (PCI DSS Req 8): broker user passwords are sensitive and MUST be<br/>sourced from a secrets manager (AWS Secrets Manager / SSM SecureString /<br/>tfvars sourced from a vault) — NEVER hardcoded or committed to source<br/>control. This whole `config` variable is marked sensitive so plan/apply<br/>output never echoes the passwords. | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    broker_name = string       # broker name; also basis for SG/KMS names<br/>    vpc_id      = string       # VPC the broker SG lives in<br/>    subnet_ids  = list(string) # subnets the broker is placed in<br/><br/>    # --- Engine / placement (secure defaults) ---<br/>    engine_type        = optional(string, "ActiveMQ")<br/>    host_instance_type = optional(string, "mq.m5.large")<br/>    deployment_mode    = optional(string, "ACTIVE_STANDBY_MULTI_AZ")<br/><br/>    # --- Encryption at rest (PCI DSS Req 3) ---<br/>    kms_key_arn = optional(string) # BYOK: if set, no kms-key atom is created<br/><br/>    # --- Broker SG ingress (PCI DSS Req 1: no public ingress) ---<br/>    allowed_security_group_ids = optional(list(string), [])<br/>    allowed_cidrs              = optional(list(string), [])<br/><br/>    # --- Broker users (PCI DSS Req 8) ---<br/>    # Passwords MUST come from a secrets manager / tfvars-from-secret, NOT source control.<br/>    users = list(object({<br/>      username       = string<br/>      password       = string # sensitive — sourced from a vault, never hardcoded<br/>      console_access = optional(bool, false)<br/>      groups         = optional(list(string), [])<br/>    }))<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the mq (Amazon MQ) component, collected on a single object. |
<!-- END_TF_DOCS -->