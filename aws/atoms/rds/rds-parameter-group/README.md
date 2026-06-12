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
| [aws_db_parameter_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the DB parameter group. All inputs live on this single<br/>object. The caller supplies the name and the engine family; parameters are<br/>optional. Use this for standalone (non-Aurora) RDS instances. | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    name   = string # required — parameter group name<br/>    family = string # required — DB parameter group family, e.g. postgres16, mysql8.0<br/><br/>    description = optional(string, "Managed by terraform (atoms/rds-parameter-group)")<br/><br/>    # Each parameter sets one engine tunable. apply_method is "immediate" (default)<br/>    # or "pending-reboot" for static parameters.<br/>    parameters = optional(list(object({<br/>      name         = string<br/>      value        = string<br/>      apply_method = optional(string, "immediate")<br/>    })), [])<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the DB parameter group atom, collected on a single object. |
<!-- END_TF_DOCS -->