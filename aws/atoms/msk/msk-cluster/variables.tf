variable "config" {
  description = <<-EOT
    Configuration for the Amazon MSK (Managed Streaming for Apache Kafka) cluster.
    All inputs live on this single object. PCI-DSS-compliant defaults are baked
    into the optional() fields, so passing only the required fields yields a
    compliant cluster: encrypted at rest, TLS in transit + in-cluster, SASL/IAM
    auth, broker logs to CloudWatch. Insecure choices require flipping an explicit
    `allow_*` escape hatch (grep-able, audit-friendly).
  EOT

  type = object({
    cluster_name = string # required

    # --- Cluster shape ---
    kafka_version          = optional(string, "3.6.0")
    number_of_broker_nodes = optional(number, 3)
    broker_instance_type   = optional(string, "kafka.m5.large")
    client_subnets         = list(string) # required
    security_groups        = list(string) # required
    ebs_volume_size        = optional(number, 100)

    # --- Encryption at rest (PCI DSS Req 3) ---
    kms_key_arn = optional(string) # null = AWS-managed MSK key (still encrypted)
    # ESCAPE HATCH: there is no way to disable MSK at-rest encryption (AWS always
    # encrypts), this flag documents an intentional reliance on the AWS-managed key
    # instead of a customer-managed CMK. Requires a documented exception.
    allow_unencrypted_at_rest = optional(bool, false)

    # --- Encryption in transit (PCI DSS Req 4) ---
    # client_broker is forced to TLS unless allow_plaintext_in_transit=true.
    encryption_in_transit_client_broker = optional(string, "TLS")
    in_cluster_encryption               = optional(bool, true)
    # ESCAPE HATCH: permit TLS_PLAINTEXT / PLAINTEXT on client_broker.
    allow_plaintext_in_transit = optional(bool, false)

    # --- Client authentication (PCI DSS Req 7/8) ---
    sasl_iam_enabled   = optional(bool, true) # secure default
    sasl_scram_enabled = optional(bool, false)
    tls_auth_enabled   = optional(bool, false)

    # --- Monitoring (PCI DSS Req 10) ---
    enhanced_monitoring = optional(string, "PER_TOPIC_PER_BROKER")
    open_monitoring     = optional(bool, false) # Prometheus JMX + node exporters

    # --- Broker logging to CloudWatch (PCI DSS Req 10) ---
    cloudwatch_log_group_name = optional(string) # provide to enable broker logs
    # ESCAPE HATCH: permit running with broker logging disabled.
    allow_logging_disabled = optional(bool, false)

    tags = optional(map(string), {})
  })

  # no `default` here because cluster_name / client_subnets / security_groups are required

  validation {
    condition     = var.config.number_of_broker_nodes >= 1
    error_message = "config.number_of_broker_nodes must be at least 1 (and a multiple of the number of AZs in client_subnets)."
  }

  validation {
    condition     = contains(["TLS", "TLS_PLAINTEXT", "PLAINTEXT"], var.config.encryption_in_transit_client_broker)
    error_message = "config.encryption_in_transit_client_broker must be TLS, TLS_PLAINTEXT, or PLAINTEXT."
  }

  validation {
    condition     = contains(["DEFAULT", "PER_BROKER", "PER_TOPIC_PER_BROKER", "PER_TOPIC_PER_PARTITION"], var.config.enhanced_monitoring)
    error_message = "config.enhanced_monitoring must be DEFAULT, PER_BROKER, PER_TOPIC_PER_BROKER, or PER_TOPIC_PER_PARTITION."
  }

  validation {
    condition     = var.config.sasl_iam_enabled || var.config.sasl_scram_enabled || var.config.tls_auth_enabled
    error_message = "At least one client authentication method must be enabled (sasl_iam_enabled, sasl_scram_enabled, or tls_auth_enabled)."
  }
}
