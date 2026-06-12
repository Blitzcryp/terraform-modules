variable "config" {
  description = <<-EOT
    Configuration for the RDS Proxy. All inputs live on this single object.
    PCI-DSS-compliant defaults are baked into the optional() fields: TLS is
    required for client connections and authentication is delegated to AWS
    Secrets Manager + IAM (PCI DSS Req 8: no clear-text credentials). The proxy
    fronts EXACTLY ONE target — a DB instance OR a DB cluster. Insecure choices
    require flipping an explicit `allow_*` escape hatch (grep-able, auditable).
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    name           = string       # required — proxy name
    engine_family  = string       # required — MYSQL | POSTGRESQL | SQLSERVER
    secret_arns    = list(string) # required — Secrets Manager secret ARNs holding DB creds
    role_arn       = string       # required — IAM role granting the proxy access to the secrets
    vpc_subnet_ids = list(string) # required — subnets the proxy ENIs live in

    vpc_security_group_ids = optional(list(string), [])

    # --- Connection behaviour ---
    idle_client_timeout = optional(number, 1800)
    debug_logging       = optional(bool, false)

    # --- Encryption in transit (PCI DSS Req 4: protect data in transit) ---
    require_tls = optional(bool, true)

    # --- Target: exactly one of these must be set ---
    target_db_instance_identifier = optional(string)
    target_db_cluster_identifier  = optional(string)

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_plaintext = optional(bool, false) # permit require_tls=false
  })
  # no `default` — name / engine_family / secret_arns / role_arn / vpc_subnet_ids are required

  validation {
    condition     = contains(["MYSQL", "POSTGRESQL", "SQLSERVER"], var.config.engine_family)
    error_message = "config.engine_family must be MYSQL, POSTGRESQL, or SQLSERVER."
  }

  validation {
    condition     = length(var.config.secret_arns) >= 1
    error_message = "config.secret_arns must list at least one Secrets Manager secret ARN."
  }

  validation {
    # Exactly one target: a DB instance OR a DB cluster, never both / neither.
    condition = length(compact([
      var.config.target_db_instance_identifier,
      var.config.target_db_cluster_identifier,
    ])) == 1
    error_message = "Set EXACTLY ONE of config.target_db_instance_identifier or config.target_db_cluster_identifier."
  }
}
