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
| [aws_dynamodb_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the DynamoDB table atom. All inputs live on this single<br/>object. PCI-DSS-compliant defaults are baked into the optional() fields:<br/>encryption at rest with a customer-managed key (Req 3), point-in-time<br/>recovery on, and deletion protection on. Insecure choices require flipping an<br/>explicit `allow_*` escape hatch. | <pre>object({<br/>    # --- Required ---<br/>    name     = string<br/>    hash_key = string<br/>    attributes = list(object({<br/>      name = string<br/>      type = string # S | N | B<br/>    }))<br/><br/>    # --- Optional schema ---<br/>    range_key                = optional(string)<br/>    billing_mode             = optional(string, "PAY_PER_REQUEST")<br/>    read_capacity            = optional(number) # required only for PROVISIONED<br/>    write_capacity           = optional(number) # required only for PROVISIONED<br/>    global_secondary_indexes = optional(list(any), [])<br/>    local_secondary_indexes  = optional(list(any), [])<br/>    ttl_attribute            = optional(string) # null = TTL disabled<br/>    stream_enabled           = optional(bool, false)<br/>    stream_view_type         = optional(string) # NEW_IMAGE | OLD_IMAGE | NEW_AND_OLD_IMAGES | KEYS_ONLY<br/><br/>    # --- Point-in-time recovery (PCI: data durability) ---<br/>    enable_point_in_time_recovery = optional(bool, true)<br/><br/>    # --- Encryption at rest (PCI DSS Req 3) ---<br/>    # When set, a customer-managed KMS key encrypts the table. When null and the<br/>    # AWS-owned-key escape hatch is flipped, the table uses the AWS-owned key.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Tagging ---<br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_aws_owned_key = optional(bool, false) # permit no CMK (AWS-owned key)<br/>    allow_no_pitr       = optional(bool, false) # permit point-in-time recovery off<br/>    allow_deletion      = optional(bool, false) # permit deletion protection off<br/><br/>    # --- Deletion safety (PCI: protect production data) ---<br/>    deletion_protection_enabled = optional(bool, true)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the DynamoDB table atom, collected on a single object. |
<!-- END_TF_DOCS -->