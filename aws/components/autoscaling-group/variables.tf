variable "config" {
  description = <<-EOT
    Configuration for the autoscaling-group component (a secure-by-default EC2
    Auto Scaling group with its own launch template, security group, IAM role,
    instance profile, and encryption key). All inputs live on this single object.
    PCI-DSS-compliant defaults are baked in: IMDSv2 enforced (Req 2), root volume
    encrypted at rest with a component-created CMK unless a BYO key is supplied
    (Req 3), and a security group with NO public ingress — only the supplied app
    security groups / CIDRs / rules may reach the instances. Required fields
    (name, image_id, vpc_id, subnet_ids) have no default, so config cannot be
    omitted.

    SECURITY: no SSH key pair is wired. Attach AmazonSSMManagedInstanceCore via
    managed_policy_arns and use SSM Session Manager for access (PCI DSS Req 8 —
    no shared/standing credentials).
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    name       = string       # ASG / resource prefix
    image_id   = string       # AMI id for the launch template
    vpc_id     = string       # VPC for the instance security group
    subnet_ids = list(string) # private subnets the ASG launches into

    # --- Instance shape ---
    instance_type    = optional(string, "t3.micro")
    user_data        = optional(string)
    root_volume_size = optional(number, 20)

    # --- Sizing ---
    min_size         = optional(number, 2)
    max_size         = optional(number, 4)
    desired_capacity = optional(number, 2)

    # --- Load balancer attachment ---
    target_group_arns = optional(list(string), [])

    # --- Encryption at rest (PCI DSS Req 3) ---
    # BYO CMK ARN; when null the component creates a dedicated KMS key.
    kms_key_arn = optional(string)

    # --- Network exposure (PCI DSS Req 1) ---
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
    managed_policy_arns = optional(list(string), [])

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_imdsv1      = optional(bool, false) # permit IMDSv1
    allow_unencrypted = optional(bool, false) # permit an unencrypted root volume
  })
  # no `default` — name, image_id, vpc_id and subnet_ids are required

  validation {
    condition     = can(regex("^ami-[0-9a-f]{8,}$", var.config.image_id))
    error_message = "config.image_id must be a valid AMI id (ami-xxxxxxxx)."
  }

  validation {
    condition     = length(var.config.subnet_ids) >= 2
    error_message = "config.subnet_ids must list at least two subnets in distinct AZs for resilience."
  }

  validation {
    condition     = var.config.min_size >= 0 && var.config.max_size >= var.config.min_size
    error_message = "config.max_size must be >= config.min_size, and both must be non-negative."
  }

  validation {
    condition     = var.config.desired_capacity >= var.config.min_size && var.config.desired_capacity <= var.config.max_size
    error_message = "config.desired_capacity must be between config.min_size and config.max_size."
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
