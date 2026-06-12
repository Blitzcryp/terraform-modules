variable "config" {
  description = <<-EOT
    Configuration for the kafka (Amazon MSK) component. All inputs live on this
    single object. PCI-DSS-compliant defaults are baked into the optional()
    fields, so the caller only has to supply the required `name`, `vpc_id` and
    `client_subnets`. The component composes a private broker security group, a
    customer-managed CMK (unless a BYO key is supplied), a KMS-encrypted broker
    log group, and an MSK cluster with TLS in transit, CMK at rest, SASL/IAM
    auth and broker logging. Insecure choices stay in the underlying atoms behind
    their own `allow_*` escape hatches.
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    name           = string       # cluster name; also basis for SG/KMS/log-group names
    vpc_id         = string       # VPC the broker SG lives in
    client_subnets = list(string) # subnets the brokers are placed in

    # --- Cluster shape (secure defaults) ---
    kafka_version          = optional(string, "3.6.0")
    number_of_broker_nodes = optional(number, 3)
    broker_instance_type   = optional(string, "kafka.m5.large")

    # --- Encryption at rest (PCI DSS Req 3) ---
    kms_key_arn = optional(string) # BYOK: if set, no kms-key atom is created

    # --- Broker SG ingress (PCI DSS Req 1: no public ingress) ---
    # Clients are admitted on the Kafka TLS ports only, by referenced SG or CIDR.
    allowed_security_group_ids = optional(list(string), [])
    allowed_cidrs              = optional(list(string), [])

    # --- Broker logging (PCI DSS Req 10) ---
    log_retention_days = optional(number, 365) # >= 1 year of audit logs

    tags = optional(map(string), {})
  })

  # no `default` here because name, vpc_id and client_subnets are required

  validation {
    condition     = length(var.config.name) > 0
    error_message = "config.name must be a non-empty string."
  }

  validation {
    condition     = length(var.config.client_subnets) > 0
    error_message = "config.client_subnets must contain at least one subnet ID."
  }

  validation {
    condition     = var.config.number_of_broker_nodes >= 1
    error_message = "config.number_of_broker_nodes must be at least 1 (and a multiple of the number of AZs in client_subnets)."
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
