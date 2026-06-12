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
| [aws_db_proxy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_proxy) | resource |
| [aws_db_proxy_default_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_proxy_default_target_group) | resource |
| [aws_db_proxy_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_proxy_target) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the RDS Proxy. All inputs live on this single object.<br/>PCI-DSS-compliant defaults are baked into the optional() fields: TLS is<br/>required for client connections and authentication is delegated to AWS<br/>Secrets Manager + IAM (PCI DSS Req 8: no clear-text credentials). The proxy<br/>fronts EXACTLY ONE target — a DB instance OR a DB cluster. Insecure choices<br/>require flipping an explicit `allow_*` escape hatch (grep-able, auditable). | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    name           = string       # required — proxy name<br/>    engine_family  = string       # required — MYSQL | POSTGRESQL | SQLSERVER<br/>    secret_arns    = list(string) # required — Secrets Manager secret ARNs holding DB creds<br/>    role_arn       = string       # required — IAM role granting the proxy access to the secrets<br/>    vpc_subnet_ids = list(string) # required — subnets the proxy ENIs live in<br/><br/>    vpc_security_group_ids = optional(list(string), [])<br/><br/>    # --- Connection behaviour ---<br/>    idle_client_timeout = optional(number, 1800)<br/>    debug_logging       = optional(bool, false)<br/><br/>    # --- Encryption in transit (PCI DSS Req 4: protect data in transit) ---<br/>    require_tls = optional(bool, true)<br/><br/>    # --- Target: exactly one of these must be set ---<br/>    target_db_instance_identifier = optional(string)<br/>    target_db_cluster_identifier  = optional(string)<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_plaintext = optional(bool, false) # permit require_tls=false<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the RDS Proxy atom, collected on a single object. |
<!-- END_TF_DOCS -->