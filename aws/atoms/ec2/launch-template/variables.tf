variable "config" {
  description = <<-EOT
    Configuration for the EC2 launch template. All inputs live on this single
    object. PCI-DSS-compliant defaults are baked into the optional() fields:
    IMDSv2 is enforced (http_tokens=required, PCI Req 2), the root volume is an
    encrypted gp3 disk (PCI Req 3), and detailed monitoring is on (PCI Req 10).
    Insecure choices require flipping an explicit `allow_*` escape hatch.

    SECURITY: prefer SSM Session Manager over `key_name` SSH keys for access
    (PCI DSS Req 8 — no shared/standing credentials). Leave key_name null and
    attach AmazonSSMManagedInstanceCore via the instance profile instead.
  EOT

  type = object({
    # --- Required: the caller must decide this ---
    name = string # launch template name

    # --- Instance shape ---
    image_id                 = optional(string)             # AMI id; may be set on the ASG/instance instead
    instance_type            = optional(string, "t3.micro") # default instance size
    vpc_security_group_ids   = optional(list(string), [])   # SGs attached to the primary ENI
    iam_instance_profile_arn = optional(string)             # instance profile ARN
    key_name                 = optional(string)             # SSH key pair; prefer SSM (see SECURITY)
    user_data                = optional(string)             # cloud-init; must already be base64-encoded

    # --- Root volume (PCI DSS Req 3: encryption at rest) ---
    root_volume_size = optional(number, 20)
    root_volume_type = optional(string, "gp3")
    kms_key_arn      = optional(string) # CMK for the root volume; null = AWS-managed EBS key

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_imdsv1      = optional(bool, false) # permit IMDSv1 (http_tokens=optional)
    allow_unencrypted = optional(bool, false) # permit an unencrypted root volume
  })

  # no `default` here because `name` is required

  validation {
    condition     = length(var.config.name) > 0
    error_message = "config.name must be a non-empty string."
  }

  validation {
    condition     = var.config.image_id == null || can(regex("^ami-[0-9a-f]{8,}$", var.config.image_id))
    error_message = "config.image_id, when set, must be a valid AMI id (ami-xxxxxxxx)."
  }

  validation {
    condition     = var.config.root_volume_size >= 8
    error_message = "config.root_volume_size must be at least 8 GiB."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }
}
