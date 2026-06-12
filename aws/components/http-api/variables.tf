variable "config" {
  description = <<-EOT
    Configuration for the http-api component: an API Gateway v2 HTTP API fronting
    a Lambda function, with access logging and throttling on by default. The
    component composes the apigatewayv2-api + apigatewayv2-integration (AWS_PROXY
    to the Lambda) + N apigatewayv2-route (one per entry in `routes`) atoms, plus
    an encrypted CloudWatch log group for access logs and a customer-managed KMS
    key (created unless a BYO key is supplied).

    PCI-compliant defaults: access logging is wired to a KMS-encrypted log group
    retained for one year (Req 10), and default-route throttling is enabled to
    protect the backend. TLS is implicit and enforced by API Gateway.

    APPLY-TIME NOTE: API Gateway needs permission to invoke the Lambda. This
    component does NOT create the aws_lambda_permission (it would couple the
    component to a Lambda it does not own). The caller must add a permission
    granting principal apigateway.amazonaws.com invoke on the function, scoped to
    "<manifest.execution_arn>/*/*" as source_arn. The lambda-permission atom
    exists for this.
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    name              = string # API + log group base name
    lambda_invoke_arn = string # Lambda invoke ARN the AWS_PROXY integration targets

    # --- Routing ---
    # Route keys, e.g. ["GET /items", "POST /items"] or the catch-all "$default".
    routes = optional(list(string), ["$default"])

    # --- CORS (empty = no CORS configuration on the API) ---
    cors_allow_origins = optional(list(string), [])

    # --- Throttling (protect the backend; PCI hardening) ---
    throttling_burst_limit = optional(number, 5000)
    throttling_rate_limit  = optional(number, 10000)

    # --- Encryption (PCI DSS Req 3) ---
    # BYO CMK for the access-log group. When null this component creates a CMK
    # whose key policy authorises CloudWatch Logs in this region.
    kms_key_arn = optional(string)

    # --- Observability (PCI DSS Req 10) ---
    log_retention_days = optional(number, 365)

    tags = optional(map(string), {})
  })

  # no `default` because name and lambda_invoke_arn are required

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,128}$", var.config.name))
    error_message = "config.name must be 1-128 chars of letters, numbers, hyphens, or underscores."
  }

  validation {
    condition     = length(var.config.routes) > 0
    error_message = "config.routes must contain at least one route key."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }
}
