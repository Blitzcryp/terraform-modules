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
| <a name="module_ci_role"></a> [ci\_role](#module\_ci\_role) | ../../atoms/iam/iam-role | n/a |
| <a name="module_oidc_provider"></a> [oidc\_provider](#module\_oidc\_provider) | ../../atoms/iam/iam-oidc-provider | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the keyless CI/CD OIDC role component (PCI DSS Req 8 — no<br/>long-lived static keys; CI assumes a role via OIDC). All inputs live on this<br/>single object. PCI-compliant defaults are baked into the optional() fields,<br/>so the caller only has to supply the required `role_name` and `subjects`<br/>(the scoped OIDC subjects allowed to assume the role). Insecure choices<br/>require flipping an explicit `allow_*` escape hatch. | <pre>object({<br/>    # role_name is REQUIRED: the identity of the CI/CD role.<br/>    role_name = string<br/>    # subjects is REQUIRED: the scoped OIDC `sub` claims allowed to assume the<br/>    # role, e.g. ["repo:org/repo:ref:refs/heads/main"]. A scoped sub is the<br/>    # whole point of OIDC federation (PCI DSS Req 8).<br/>    subjects = list(string)<br/><br/>    provider_url = optional(string, "token.actions.githubusercontent.com")<br/>    client_ids   = optional(list(string), ["sts.amazonaws.com"])<br/>    thumbprints  = optional(list(string), [])<br/><br/>    # Provider ownership: by default this component creates the OIDC provider.<br/>    # Set create_provider=false and supply provider_arn to reuse an existing one<br/>    # (one OIDC provider per issuer per account).<br/>    create_provider = optional(bool, true)<br/>    provider_arn    = optional(string)<br/><br/>    managed_policy_arns  = optional(list(string), [])<br/>    inline_policies      = optional(map(string), {})<br/>    permissions_boundary = optional(string)<br/>    max_session_duration = optional(number, 3600)<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_wildcard_subject = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the iam-ci-oidc component, collected on a single object. |
<!-- END_TF_DOCS -->