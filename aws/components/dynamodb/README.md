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
| <a name="module_table"></a> [table](#module\_table) | ../../atoms/dynamodb/dynamodb-table | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the dynamodb component (an encrypted DynamoDB table<br/>capability). All inputs live on this single object. PCI-DSS-compliant<br/>defaults are baked into the optional() fields: the table is encrypted at rest<br/>with a customer-managed KMS key (Req 3), point-in-time recovery is on, and<br/>deletion protection is on.<br/><br/>This component composes atoms via module blocks: a kms-key atom (the CMK that<br/>encrypts the table — created unless a `kms_key_arn` is supplied) and a<br/>dynamodb-table atom. | <pre>object({<br/>    # --- Required ---<br/>    name     = string<br/>    hash_key = string<br/>    attributes = list(object({<br/>      name = string<br/>      type = string # S | N | B<br/>    }))<br/><br/>    # --- Optional schema ---<br/>    range_key                = optional(string)<br/>    billing_mode             = optional(string, "PAY_PER_REQUEST")<br/>    global_secondary_indexes = optional(list(any), [])<br/>    ttl_attribute            = optional(string)<br/>    stream_enabled           = optional(bool, false)<br/>    stream_view_type         = optional(string)<br/><br/>    # --- Encryption (PCI DSS Req 3) ---<br/>    # BYOK: when set, the supplied CMK encrypts the table and no kms-key atom is<br/>    # created. When null, a dedicated kms-key atom is created for this table.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Tagging ---<br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the dynamodb component, collected on a single object. |
<!-- END_TF_DOCS -->