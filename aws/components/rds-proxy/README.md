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
| <a name="module_proxy"></a> [proxy](#module\_proxy) | ../../atoms/rds/rds-proxy | n/a |
| <a name="module_role"></a> [role](#module\_role) | ../../atoms/iam/iam-role | n/a |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | ../../atoms/vpc/security-group | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the rds-proxy component (connection pooling + IAM auth in<br/>front of an RDS database). All inputs live on this single object. The<br/>component creates a dedicated proxy security group (no public ingress), an<br/>IAM role the proxy assumes (trusts rds.amazonaws.com, granted only<br/>secretsmanager:GetSecretValue on the supplied secret(s) plus kms:Decrypt),<br/>and the proxy itself. PCI-DSS-compliant defaults: TLS is required and<br/>authentication is delegated to Secrets Manager + IAM (no plaintext creds).<br/>The proxy fronts EXACTLY ONE target — a DB instance OR a DB cluster. | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    name          = string       # required — proxy name<br/>    vpc_id        = string       # required — VPC for the proxy security group<br/>    subnet_ids    = list(string) # required — subnets the proxy ENIs live in<br/>    engine_family = string       # required — MYSQL | POSTGRESQL | SQLSERVER<br/>    secret_arns   = list(string) # required — Secrets Manager secret ARNs holding DB creds<br/><br/>    # --- Target: exactly one of these must be set ---<br/>    target_db_instance_identifier = optional(string)<br/>    target_db_cluster_identifier  = optional(string)<br/><br/>    # --- Network exposure (PCI DSS Req 1) ---<br/>    # Proxy-port ingress is allowed ONLY from these app security groups / CIDRs.<br/>    allowed_security_group_ids = optional(list(string), [])<br/>    allowed_cidrs              = optional(list(string), [])<br/><br/>    # --- Encryption in transit (PCI DSS Req 4) ---<br/>    require_tls = optional(bool, true)<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_plaintext = optional(bool, false) # permit require_tls=false<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the rds-proxy component, collected on a single object. |
<!-- END_TF_DOCS -->