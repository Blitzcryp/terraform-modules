variable "config" {
  description = <<-EOT
    Configuration for the rds-proxy component (connection pooling + IAM auth in
    front of an RDS database). All inputs live on this single object. The
    component creates a dedicated proxy security group (no public ingress), an
    IAM role the proxy assumes (trusts rds.amazonaws.com, granted only
    secretsmanager:GetSecretValue on the supplied secret(s) plus kms:Decrypt),
    and the proxy itself. PCI-DSS-compliant defaults: TLS is required and
    authentication is delegated to Secrets Manager + IAM (no plaintext creds).
    The proxy fronts EXACTLY ONE target — a DB instance OR a DB cluster.
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    name          = string       # required — proxy name
    vpc_id        = string       # required — VPC for the proxy security group
    subnet_ids    = list(string) # required — subnets the proxy ENIs live in
    engine_family = string       # required — MYSQL | POSTGRESQL | SQLSERVER
    secret_arns   = list(string) # required — Secrets Manager secret ARNs holding DB creds

    # --- Target: exactly one of these must be set ---
    target_db_instance_identifier = optional(string)
    target_db_cluster_identifier  = optional(string)

    # --- Network exposure (PCI DSS Req 1) ---
    # Proxy-port ingress is allowed ONLY from these app security groups / CIDRs.
    allowed_security_group_ids = optional(list(string), [])
    allowed_cidrs              = optional(list(string), [])

    # --- Encryption in transit (PCI DSS Req 4) ---
    require_tls = optional(bool, true)

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_plaintext = optional(bool, false) # permit require_tls=false
  })
  # no `default` — name, vpc_id, subnet_ids, engine_family, secret_arns are required

  validation {
    condition     = contains(["MYSQL", "POSTGRESQL", "SQLSERVER"], var.config.engine_family)
    error_message = "config.engine_family must be MYSQL, POSTGRESQL, or SQLSERVER."
  }

  validation {
    condition     = length(var.config.secret_arns) >= 1
    error_message = "config.secret_arns must list at least one Secrets Manager secret ARN."
  }

  validation {
    condition = length(compact([
      var.config.target_db_instance_identifier,
      var.config.target_db_cluster_identifier,
    ])) == 1
    error_message = "Set EXACTLY ONE of config.target_db_instance_identifier or config.target_db_cluster_identifier."
  }

  validation {
    condition     = alltrue([for c in var.config.allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "Each config.allowed_cidrs entry must be a valid IPv4 CIDR (e.g. 10.0.0.0/16)."
  }
}
