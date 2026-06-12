variable "config" {
  description = <<-EOT
    Configuration for the efs component: an encrypted, shared NFS file system for
    a VPC. All inputs live on this single object. PCI-DSS-compliant defaults are
    baked in: the file system is encrypted at rest (Req 3) with a dedicated KMS
    key (created when no BYO key is supplied), a file-system policy denies any
    non-TLS access (Req 4), one mount target is created per supplied subnet, and
    the mount-target security group permits NFS (TCP 2049) ONLY from the supplied
    app security groups / CIDRs — never from the public internet (Req 1).
    Required fields (name, vpc_id, subnet_ids) have no default.
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    name       = string       # required — naming prefix / creation token
    vpc_id     = string       # required — VPC for the mount-target security group
    subnet_ids = list(string) # required — one mount target is created per subnet

    # --- Encryption at rest (PCI DSS Req 3) ---
    # BYO CMK ARN; when null the component creates a dedicated KMS key.
    kms_key_arn = optional(string)

    # --- Network exposure (PCI DSS Req 1) ---
    # NFS (2049) ingress is allowed ONLY from these app security groups / CIDRs.
    # Empty lists => a security group with no ingress at all (most locked-down).
    allowed_security_group_ids = optional(list(string), [])
    allowed_cidrs              = optional(list(string), [])

    # --- Performance ---
    performance_mode = optional(string, "generalPurpose")

    # --- Access points (least-privilege POSIX entry points; PCI DSS Req 7) ---
    access_points = optional(map(object({
      posix_user = optional(object({
        uid            = number
        gid            = number
        secondary_gids = optional(list(number), [])
      }))
      root_directory = optional(object({
        path = string
        creation_info = optional(object({
          owner_uid   = number
          owner_gid   = number
          permissions = string
        }))
      }))
    })), {})

    tags = optional(map(string), {})
  })
  # no `default` — name, vpc_id and subnet_ids are required

  validation {
    condition     = length(var.config.subnet_ids) >= 1
    error_message = "config.subnet_ids must list at least one subnet (one mount target is created per subnet)."
  }

  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.config.performance_mode)
    error_message = "config.performance_mode must be generalPurpose or maxIO."
  }

  validation {
    condition     = alltrue([for c in var.config.allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "Each config.allowed_cidrs entry must be a valid IPv4 CIDR (e.g. 10.0.0.0/16)."
  }
}
