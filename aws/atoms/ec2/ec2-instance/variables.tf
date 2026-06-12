variable "config" {
  description = <<-EOT
    Configuration for the EC2 instance. All inputs live on this single object.
    PCI-DSS-compliant defaults are baked into the optional() fields: IMDSv2 is
    enforced (PCI Req 2), the root volume is encrypted at rest (PCI Req 3), no
    public IP is assigned (PCI Req 1), detailed monitoring and EBS optimization
    are on. Insecure choices require flipping an explicit `allow_*` escape hatch.

    SECURITY: prefer SSM Session Manager over `key_name` SSH keys for access
    (PCI DSS Req 8 — no shared/standing credentials). Leave key_name null and
    attach AmazonSSMManagedInstanceCore via the instance profile instead.
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    ami                    = string       # AMI id to launch
    subnet_id              = string       # subnet the ENI lands in
    vpc_security_group_ids = list(string) # SGs attached to the primary ENI

    # --- Instance shape ---
    instance_type        = optional(string, "t3.micro")
    iam_instance_profile = optional(string) # instance profile NAME (not ARN)
    key_name             = optional(string) # SSH key pair; prefer SSM (see SECURITY)
    user_data            = optional(string) # cloud-init; rendered base64 by the provider

    # --- Root volume (PCI DSS Req 3: encryption at rest) ---
    root_volume_size = optional(number, 20)
    root_volume_type = optional(string, "gp3")
    kms_key_arn      = optional(string) # CMK for root + extra volumes; null = AWS-managed EBS key

    # Additional EBS data volumes. Each is encrypted by default (uses kms_key_arn).
    ebs_block_devices = optional(list(object({
      device_name = string
      volume_size = optional(number, 20)
      volume_type = optional(string, "gp3")
      iops        = optional(number)
      throughput  = optional(number)
      encrypted   = optional(bool, true)
    })), [])

    # --- Secure-by-default toggles ---
    monitoring                  = optional(bool, true)  # detailed CloudWatch monitoring (PCI Req 10)
    ebs_optimized               = optional(bool, true)  # dedicated EBS throughput
    associate_public_ip_address = optional(bool, false) # PCI Req 1: stay private

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_imdsv1      = optional(bool, false) # permit IMDSv1 (http_tokens=optional)
    allow_unencrypted = optional(bool, false) # permit an unencrypted root volume
    allow_public_ip   = optional(bool, false) # permit associate_public_ip_address=true
  })

  # no `default` here because ami / subnet_id / vpc_security_group_ids are required

  validation {
    condition     = can(regex("^ami-[0-9a-f]{8,}$", var.config.ami))
    error_message = "config.ami must be a valid AMI id (ami-xxxxxxxx)."
  }

  validation {
    condition     = length(var.config.vpc_security_group_ids) > 0
    error_message = "config.vpc_security_group_ids must contain at least one security group id."
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
