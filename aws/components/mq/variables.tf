variable "config" {
  description = <<-EOT
    Configuration for the mq (Amazon MQ) component. All inputs live on this
    single object. PCI-DSS-compliant defaults are baked into the optional()
    fields, so the caller only has to supply the required `broker_name`,
    `vpc_id`, `subnet_ids` and `users`. The component composes a private broker
    security group, a customer-managed CMK (unless a BYO key is supplied), and an
    Amazon MQ broker that is NOT publicly accessible, encrypted with the CMK at
    rest, with general + audit logging on.

    SECURITY (PCI DSS Req 8): broker user passwords are sensitive and MUST be
    sourced from a secrets manager (AWS Secrets Manager / SSM SecureString /
    tfvars sourced from a vault) — NEVER hardcoded or committed to source
    control. This whole `config` variable is marked sensitive so plan/apply
    output never echoes the passwords.
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    broker_name = string       # broker name; also basis for SG/KMS names
    vpc_id      = string       # VPC the broker SG lives in
    subnet_ids  = list(string) # subnets the broker is placed in

    # --- Engine / placement (secure defaults) ---
    engine_type        = optional(string, "ActiveMQ")
    host_instance_type = optional(string, "mq.m5.large")
    deployment_mode    = optional(string, "ACTIVE_STANDBY_MULTI_AZ")

    # --- Encryption at rest (PCI DSS Req 3) ---
    kms_key_arn = optional(string) # BYOK: if set, no kms-key atom is created

    # --- Broker SG ingress (PCI DSS Req 1: no public ingress) ---
    allowed_security_group_ids = optional(list(string), [])
    allowed_cidrs              = optional(list(string), [])

    # --- Broker users (PCI DSS Req 8) ---
    # Passwords MUST come from a secrets manager / tfvars-from-secret, NOT source control.
    users = list(object({
      username       = string
      password       = string # sensitive — sourced from a vault, never hardcoded
      console_access = optional(bool, false)
      groups         = optional(list(string), [])
    }))

    tags = optional(map(string), {})
  })

  sensitive = true # protects the embedded broker user passwords (PCI DSS Req 8)

  # no `default` here because broker_name, vpc_id, subnet_ids and users are required

  validation {
    condition     = length(var.config.broker_name) > 0
    error_message = "config.broker_name must be a non-empty string."
  }

  validation {
    condition     = length(var.config.subnet_ids) > 0
    error_message = "config.subnet_ids must contain at least one subnet ID."
  }

  validation {
    condition     = contains(["ActiveMQ", "RabbitMQ"], var.config.engine_type)
    error_message = "config.engine_type must be ActiveMQ or RabbitMQ."
  }

  validation {
    condition     = contains(["SINGLE_INSTANCE", "ACTIVE_STANDBY_MULTI_AZ", "CLUSTER_MULTI_AZ"], var.config.deployment_mode)
    error_message = "config.deployment_mode must be SINGLE_INSTANCE, ACTIVE_STANDBY_MULTI_AZ, or CLUSTER_MULTI_AZ."
  }

  validation {
    condition     = length(var.config.users) >= 1
    error_message = "config.users must contain at least one broker user (username + password from a secrets manager)."
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
