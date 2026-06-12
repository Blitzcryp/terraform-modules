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
| [aws_secretsmanager_secret.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_policy) | resource |
| [aws_secretsmanager_secret_rotation.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_rotation) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the Secrets Manager secret atom. All inputs live on this<br/>single object. PCI-DSS-compliant defaults are baked into the optional()<br/>fields: the secret is encrypted with a customer-managed KMS key (Req 3) and<br/>deletion uses a 30-day recovery window. Insecure choices require flipping an<br/>explicit `allow_*` escape hatch.<br/><br/>SECURITY: This module never sets the secret's value. The secret material is<br/>created/rotated out-of-band (a secrets source, a rotation Lambda, or manual<br/>population) — never in Terraform source control (PCI DSS Req 3.5 / Req 8). | <pre>object({<br/>    # --- Required: the caller must decide the secret name. ---<br/>    name = string<br/><br/>    description = optional(string, "Managed by terraform (atoms/secretsmanager/secretsmanager-secret)")<br/><br/>    # --- Encryption at rest (PCI DSS Req 3) ---<br/>    # CMK ARN that encrypts the secret. When null the secret falls back to the<br/>    # AWS-managed `aws/secretsmanager` key, which is less strict — that path is<br/>    # gated behind the allow_aws_managed_key escape hatch.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Deletion safety ---<br/>    # 7-30 = recovery window (longer is safer); 0 = immediate, irreversible<br/>    # deletion (gated behind allow_immediate_deletion).<br/>    recovery_window_in_days = optional(number, 30)<br/><br/>    # --- Optional rotation (PCI DSS Req 8: rotate credentials) ---<br/>    # When rotation_lambda_arn is set, a rotation schedule is created.<br/>    rotation_lambda_arn = optional(string)<br/>    rotation_days       = optional(number, 30)<br/><br/>    # --- Optional resource policy (JSON). null = no resource policy. ---<br/>    policy = optional(string)<br/><br/>    # --- Tagging ---<br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_aws_managed_key    = optional(bool, false) # permit kms_key_arn = null<br/>    allow_immediate_deletion = optional(bool, false) # permit recovery_window_in_days = 0<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the Secrets Manager secret atom, collected on a single object. |
<!-- END_TF_DOCS -->