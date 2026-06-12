variable "config" {
  description = <<-EOT
    Configuration for a single VPC endpoint. All inputs live on this single
    object. `vpc_id` and `service_name` are required (the caller must decide
    them). PCI-DSS-compliant defaults are baked into the optional() fields:
    the endpoint is an Interface endpoint with private DNS ON, so service
    traffic resolves to private addresses and stays off the public internet
    (PCI DSS Req 1 — network segmentation).
  EOT

  type = object({
    vpc_id       = string # required — the caller must decide this
    service_name = string # required — full service name, e.g. com.amazonaws.eu-central-1.s3

    # Interface (default) keeps traffic private via an ENI + private DNS.
    # Gateway is used for S3/DynamoDB and attaches to route tables instead.
    vpc_endpoint_type = optional(string, "Interface")

    # --- Interface-endpoint wiring -------------------------------------
    subnet_ids         = optional(list(string), []) # ENIs are placed in these (private) subnets
    security_group_ids = optional(list(string), []) # SGs guarding the ENIs (allow 443 from the VPC)
    # Private DNS makes the public service name resolve to the endpoint's
    # private addresses, so existing clients reach the service without
    # touching the internet (PCI DSS Req 1 segmentation). Secure default = ON.
    private_dns_enabled = optional(bool, true)

    # --- Gateway-endpoint wiring ---------------------------------------
    route_table_ids = optional(list(string), []) # route tables that get the prefix-list route

    # Optional endpoint policy (null = full-access default applied by AWS).
    policy = optional(string)

    tags = optional(map(string), {})
  })

  # no `default` here because vpc_id and service_name are required

  validation {
    condition     = contains(["Interface", "Gateway", "GatewayLoadBalancer"], var.config.vpc_endpoint_type)
    error_message = "config.vpc_endpoint_type must be one of Interface, Gateway, or GatewayLoadBalancer."
  }
}
