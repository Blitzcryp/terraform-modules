variable "config" {
  description = <<-EOT
    Configuration for the ECR repository. All inputs live on this single object.
    PCI-DSS-compliant defaults are baked into the optional() fields, so passing
    only the required `name` yields a compliant repository: scan-on-push enabled
    (Req 6 vuln mgmt), immutable tags (image integrity), encryption at rest
    (Req 3), and a lifecycle policy expiring untagged images. Insecure choices
    require flipping an explicit `allow_*` escape hatch.
  EOT

  type = object({
    name = string # required — the repository name

    # --- Secure-by-default controls ---
    # PCI DSS Req 6: scan images for vulnerabilities on push.
    scan_on_push = optional(bool, true)
    # Image integrity: immutable tags prevent silent overwrite of a tag.
    image_tag_mutability = optional(string, "IMMUTABLE")
    # PCI DSS Req 3: encryption at rest. KMS key ARN; null = AWS-managed AES256.
    kms_key_arn = optional(string)
    # Lifecycle policy: expire untagged images after N days; keep last N tagged.
    untagged_expiry_days = optional(number, 14)
    tagged_image_count   = optional(number, 30)
    # Optional repository policy JSON (resource-based access policy).
    additional_repository_policy = optional(string)
    force_delete                 = optional(bool, false)
    tags                         = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_scan_on_push_disabled = optional(bool, false)
    allow_mutable_tags          = optional(bool, false)
  })
  # `name` is required, so no `default = {}`.

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.config.image_tag_mutability)
    error_message = "config.image_tag_mutability must be MUTABLE or IMMUTABLE."
  }

  validation {
    condition     = var.config.untagged_expiry_days >= 1
    error_message = "config.untagged_expiry_days must be >= 1."
  }

  validation {
    condition     = var.config.tagged_image_count >= 1
    error_message = "config.tagged_image_count must be >= 1."
  }
}
