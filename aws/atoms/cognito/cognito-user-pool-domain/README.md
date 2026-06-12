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
| [aws_cognito_user_pool_domain.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_domain) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the Cognito user pool domain atom. Associates a hosted-UI<br/>domain with a user pool. Pass `certificate_arn` to serve a custom domain<br/>over an ACM-issued certificate (TLS); omit it to use a Cognito-prefix domain.<br/>All inputs live on this single object. | <pre>object({<br/>    domain       = string # required — no default<br/>    user_pool_id = string # required — no default<br/><br/>    # --- Custom domain TLS certificate (ACM, us-east-1) ---<br/>    certificate_arn = optional(string)<br/><br/>    # aws_cognito_user_pool_domain is NOT a taggable resource. `tags` is accepted<br/>    # for interface uniformity across atoms but is intentionally not applied to<br/>    # any resource here. Documented per CONVENTIONS §5.<br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the Cognito user pool domain atom, collected on a single object. |
<!-- END_TF_DOCS -->