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
| [aws_backup_selection.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the AWS Backup selection atom. A selection binds a set of<br/>resources (by ARN and/or by tag) to a backup plan, assuming the supplied IAM<br/>role to perform the backups (PCI DSS Req 7 least privilege). All inputs live<br/>on this single object.<br/><br/>NOTE on tags: aws\_backup\_selection is NOT a taggable resource. A `tags` field<br/>is accepted on this config for interface uniformity across the library, but<br/>it is intentionally NOT applied to the resource (there is nowhere to put it).<br/>Use `selection_tags` to choose which tagged resources are backed up. | <pre>object({<br/>    # All three are REQUIRED: the selection is meaningless without a name, a plan<br/>    # to attach to, and the role used to perform the backups.<br/>    name         = string<br/>    plan_id      = string<br/>    iam_role_arn = string<br/><br/>    # What to back up: explicit ARNs, exclusions, and/or tag-based matching.<br/>    resources     = optional(list(string), [])<br/>    not_resources = optional(list(string), [])<br/>    selection_tags = optional(list(object({<br/>      type  = optional(string, "STRINGEQUALS")<br/>      key   = string<br/>      value = string<br/>    })), [])<br/><br/>    # Accepted for interface uniformity only; NOT applied (resource not taggable).<br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the AWS Backup selection atom, collected on a single object. |
<!-- END_TF_DOCS -->