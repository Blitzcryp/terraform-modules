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
| [aws_elasticache_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_subnet_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the ElastiCache subnet group. All inputs live on this single<br/>object. The caller supplies the name and the (private) subnet IDs; everything<br/>else has a sensible default. | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    name       = string       # required — subnet group name<br/>    subnet_ids = list(string) # required — subnets the cache nodes may live in<br/><br/>    description = optional(string, "Managed by terraform (atoms/elasticache/elasticache-subnet-group)")<br/>    tags        = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the ElastiCache subnet group atom, collected on a single object. |
<!-- END_TF_DOCS -->