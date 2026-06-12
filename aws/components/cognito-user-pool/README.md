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
| <a name="module_user_pool"></a> [user\_pool](#module\_user\_pool) | ../../atoms/cognito/cognito-user-pool | n/a |
| <a name="module_user_pool_client"></a> [user\_pool\_client](#module\_user\_pool\_client) | ../../atoms/cognito/cognito-user-pool-client | n/a |
| <a name="module_user_pool_domain"></a> [user\_pool\_domain](#module\_user\_pool\_domain) | ../../atoms/cognito/cognito-user-pool-domain | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the hardened Cognito user pool capability (PCI DSS Req 8:<br/>identify & authenticate access). Composes a user pool, an app client, and an<br/>optional hosted-UI domain. All inputs live on this single object. Passing<br/>only `name` yields a fully hardened stack: MFA enforced (ON) with TOTP,<br/>advanced security ENFORCED, 14-char complex passwords, a confidential client<br/>with a generated secret, authorization-code OAuth only (no implicit flow),<br/>and SRP auth (no password grant). The component surfaces no escape hatches —<br/>weakening a control means dropping to the underlying atoms directly. | <pre>object({<br/>    name = string # required — no default<br/><br/>    # --- Pool security knobs (map onto the cognito-user-pool atom) ---<br/>    mfa_configuration       = optional(string, "ON") # OFF | ON | OPTIONAL<br/>    password_minimum_length = optional(number, 14)<br/><br/>    # --- Client knobs (map onto the cognito-user-pool-client atom) ---<br/>    callback_urls          = optional(list(string), [])<br/>    allowed_oauth_scopes   = optional(list(string), ["openid", "email"])<br/>    generate_client_secret = optional(bool, true)<br/><br/>    # --- Optional hosted-UI domain (creates the domain atom only when set) ---<br/>    domain          = optional(string)<br/>    certificate_arn = optional(string)<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the hardened Cognito user pool component, collected on a single object. client\_secret is sensitive. |
<!-- END_TF_DOCS -->