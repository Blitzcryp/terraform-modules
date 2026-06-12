variable "config" {
  description = <<-EOT
    Configuration for the vpc-endpoints component. All inputs live on this single
    object. `vpc_id` is required (the caller must decide it). PCI-DSS-compliant
    defaults are baked into the optional() fields: a curated set of Gateway
    (S3, DynamoDB) and Interface (ECR, Logs, Secrets Manager, KMS, SSM, STS,
    monitoring) endpoints is created so that workloads reach those AWS services
    privately, keeping traffic off the public internet (PCI DSS Req 1 — network
    segmentation). The component builds full service names as
    com.amazonaws.<region>.<short> using the current region.
  EOT

  type = object({
    vpc_id = string # required — the caller must decide this

    # Where to wire the endpoints. Interface endpoints place ENIs in these
    # (private) subnets; Gateway endpoints install routes in these route tables.
    private_subnet_ids      = optional(list(string), [])
    private_route_table_ids = optional(list(string), [])

    # Short service names (without the com.amazonaws.<region>. prefix). The
    # defaults are the common set of AWS services a private workload needs.
    gateway_services   = optional(list(string), ["s3", "dynamodb"])
    interface_services = optional(list(string), ["ecr.api", "ecr.dkr", "logs", "secretsmanager", "kms", "ssm", "ssmmessages", "ec2messages", "sts", "monitoring"])

    # CIDRs permitted to reach the Interface endpoint ENIs on 443. Empty (the
    # default) means "the VPC's own CIDR", looked up via data.aws_vpc — so only
    # in-VPC traffic can use the endpoints (PCI DSS Req 1).
    allowed_cidrs = optional(list(string), [])

    tags = optional(map(string), {})
  })

  # no `default` here because vpc_id is required

  validation {
    condition     = length(var.config.interface_services) == 0 || length(var.config.private_subnet_ids) > 0
    error_message = "config.private_subnet_ids must be provided when config.interface_services is non-empty (Interface endpoints need subnets for their ENIs)."
  }

  validation {
    condition     = length(var.config.gateway_services) == 0 || length(var.config.private_route_table_ids) > 0
    error_message = "config.private_route_table_ids must be provided when config.gateway_services is non-empty (Gateway endpoints need route tables)."
  }

  validation {
    condition     = alltrue([for c in var.config.allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "Each config.allowed_cidrs entry must be a valid IPv4 CIDR (e.g. 10.0.0.0/16)."
  }
}
