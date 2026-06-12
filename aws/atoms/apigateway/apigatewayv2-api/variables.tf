variable "config" {
  description = <<-EOT
    Configuration for the API Gateway v2 (HTTP/WebSocket) API. All inputs live on
    this single object. PCI-compliant behaviour is provided by composition (the
    http-api component wires access logging + throttling on the stage); this atom
    owns only the API resource itself.

    NOTE: set disable_execute_api_endpoint=true when fronting the API with a
    custom domain so the default execute-api endpoint cannot be used to bypass
    domain-level controls (WAF, TLS policy).
  EOT

  type = object({
    # name is REQUIRED: the caller must decide the API name. No default.
    name = string

    protocol_type                = optional(string, "HTTP")
    disable_execute_api_endpoint = optional(bool, false)

    cors_configuration = optional(object({
      allow_credentials = optional(bool)
      allow_headers     = optional(list(string))
      allow_methods     = optional(list(string))
      allow_origins     = optional(list(string))
      expose_headers    = optional(list(string))
      max_age           = optional(number)
    }))

    tags = optional(map(string), {})
  })

  # no `default` here because name is required

  validation {
    condition     = contains(["HTTP", "WEBSOCKET"], var.config.protocol_type)
    error_message = "config.protocol_type must be HTTP or WEBSOCKET."
  }
}
