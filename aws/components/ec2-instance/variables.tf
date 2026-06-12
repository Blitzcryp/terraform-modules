variable "config" {
  description = <<-EOT
    Configuration for the ec2-instance component (a standalone, secure-by-default
    EC2 instance with its own security group, IAM role, instance profile, and
    encryption key). All inputs live on this single object. PCI-DSS-compliant
    defaults are baked in: IMDSv2 enforced (Req 2), root volume encrypted at rest
    with a component-created CMK unless a BYO key is supplied (Req 3), no public
    IP (Req 1), and a security group with NO public ingress — only the supplied
    app security groups / CIDRs / rules may reach the instance. Required fields
    (name, ami, vpc_id, subnet_id) have no default, so config cannot be omitted.

    SECURITY: no SSH key pair is wired. Attach AmazonSSMManagedInstanceCore via
    managed_policy_arns and use SSM Session Manager for access (PCI DSS Req 8 —
    no shared/standing credentials).
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    name      = string # instance name / resource prefix
    ami       = string # AMI id to launch
    vpc_id    = string # VPC for the instance security group
    subnet_id = string # subnet the ENI lands in

    # --- Instance shape ---
    instance_type    = optional(string, "t3.micro")
    user_data        = optional(string)
    root_volume_size = optional(number, 20)

    # --- Encryption at rest (PCI DSS Req 3) ---
    # BYO CMK ARN; when null the component creates a dedicated KMS key.
    kms_key_arn = optional(string)

    # --- Network exposure (PCI DSS Req 1) ---
    # Instance ingress is allowed ONLY from these app security groups / CIDRs, or
    # via explicit ingress_rules. Empty => a security group with no ingress at all.
    allowed_security_group_ids = optional(list(string), [])
    allowed_cidrs              = optional(list(string), [])
    ingress_rules = optional(list(object({
      description                  = string
      ip_protocol                  = string
      from_port                    = optional(number)
      to_port                      = optional(number)
      cidr_ipv4                    = optional(string)
      cidr_ipv6                    = optional(string)
      referenced_security_group_id = optional(string)
      prefix_list_id               = optional(string)
    })), [])

    # --- IAM (PCI DSS Req 7 / Req 8) ---
    # Managed policy ARNs attached to the instance role (e.g. SSM core access).
    managed_policy_arns = optional(list(string), [])

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_imdsv1      = optional(bool, false) # permit IMDSv1
    allow_unencrypted = optional(bool, false) # permit an unencrypted root volume
  })
  # no `default` — name, ami, vpc_id and subnet_id are required

  validation {
    condition     = can(regex("^ami-[0-9a-f]{8,}$", var.config.ami))
    error_message = "config.ami must be a valid AMI id (ami-xxxxxxxx)."
  }

  validation {
    condition     = var.config.root_volume_size >= 8
    error_message = "config.root_volume_size must be at least 8 GiB."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }

  validation {
    condition     = alltrue([for c in var.config.allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "Each config.allowed_cidrs entry must be a valid IPv4 CIDR (e.g. 10.0.0.0/16)."
  }
}
