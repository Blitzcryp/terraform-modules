variable "config" {
  description = <<-EOT
    Configuration for the EFS file system atom. All inputs live on this single
    object. PCI-DSS-compliant defaults are baked into the optional() fields:
    encryption at rest is ON (Req 3), and a file-system policy that denies any
    non-TLS access is attached by default (Req 4). `name` is required (it becomes
    the creation_token and the Name tag). Insecure choices require flipping an
    explicit `allow_*` escape hatch.
  EOT

  type = object({
    name = string # required — becomes creation_token and the Name tag

    # --- Encryption at rest (PCI DSS Req 3) ---
    encrypted   = optional(bool, true)
    kms_key_arn = optional(string) # null = AWS-managed aws/elasticfilesystem CMK

    # --- Performance / throughput ---
    performance_mode                = optional(string, "generalPurpose")
    throughput_mode                 = optional(string, "bursting")
    provisioned_throughput_in_mibps = optional(number) # only with throughput_mode=provisioned

    # --- Lifecycle management (cost; transition cold data to Infrequent Access) ---
    transition_to_ia = optional(string, "AFTER_30_DAYS") # null = no IA transition

    # --- Encryption in transit (PCI DSS Req 4) ---
    # When true, a file-system policy is attached denying any request where
    # aws:SecureTransport is false (i.e. non-TLS NFS mounts are rejected).
    enforce_tls = optional(bool, true)
    # Extra statements merged into the file-system policy (e.g. principal allows).
    additional_policy_statements = optional(any, [])

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_unencrypted = optional(bool, false) # permit encrypted=false
  })
  # no `default` — name is required

  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.config.performance_mode)
    error_message = "config.performance_mode must be generalPurpose or maxIO."
  }

  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.config.throughput_mode)
    error_message = "config.throughput_mode must be bursting, provisioned, or elastic."
  }

  validation {
    condition     = var.config.throughput_mode != "provisioned" || var.config.provisioned_throughput_in_mibps != null
    error_message = "config.provisioned_throughput_in_mibps is required when config.throughput_mode is provisioned."
  }

  validation {
    condition     = var.config.transition_to_ia == null || can(regex("^AFTER_(1|7|14|30|60|90)_DAYS$", var.config.transition_to_ia))
    error_message = "config.transition_to_ia must be one of AFTER_1_DAYS, AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS (or null)."
  }
}
