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
| [aws_cognito_user_pool_client.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the Cognito user pool client atom (PCI DSS Req 8: identify<br/>& authenticate access). All inputs live on this single object. PCI-compliant<br/>defaults are baked into the optional() fields, so passing only `name` and<br/>`user_pool_id` yields a hardened client: a client secret is generated, only<br/>the OAuth authorization-code flow is allowed (no insecure implicit flow),<br/>token revocation is enabled, user-existence errors are masked, and the<br/>explicit auth flows exclude the password-based grant (USER\_PASSWORD\_AUTH).<br/>Enabling the password grant requires flipping the explicit, grep-able<br/>`allow_password_auth` escape hatch. | <pre>object({<br/>    name         = string # required — no default<br/>    user_pool_id = string # required — no default<br/><br/>    # --- Client secret (confidential clients) ---<br/>    generate_secret = optional(bool, true)<br/><br/>    # --- OAuth / hosted-UI ---<br/>    callback_urls        = optional(list(string), [])<br/>    allowed_oauth_flows  = optional(list(string), ["code"]) # never "implicit" (PCI: no token in URL fragment)<br/>    allowed_oauth_scopes = optional(list(string), ["openid", "email"])<br/><br/>    # --- Auth flows (no USER_PASSWORD_AUTH by default; SRP only) ---<br/>    explicit_auth_flows = optional(list(string), ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"])<br/><br/>    # --- Token lifetimes ---<br/>    access_token_validity  = optional(number, 60) # minutes<br/>    id_token_validity      = optional(number, 60) # minutes<br/>    refresh_token_validity = optional(number, 30) # days<br/><br/>    # --- Threat protection ---<br/>    prevent_user_existence_errors = optional(string, "ENABLED") # ENABLED | LEGACY<br/>    enable_token_revocation       = optional(bool, true)<br/><br/>    # aws_cognito_user_pool_client is NOT a taggable resource. `tags` is accepted<br/>    # for interface uniformity across atoms but is intentionally not applied to<br/>    # any resource here. Documented per CONVENTIONS §5.<br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    # Permit the password-based grant (ALLOW_USER_PASSWORD_AUTH) in<br/>    # explicit_auth_flows. Sends raw credentials to the token endpoint instead<br/>    # of using SRP; weakens PCI Req 8 protections.<br/>    allow_password_auth = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the Cognito user pool client atom, collected on a single object. client\_secret is sensitive. |
<!-- END_TF_DOCS -->