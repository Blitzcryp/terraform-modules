variable "config" {
  description = <<-EOT
    Configuration for an API Gateway v2 route. All inputs live on this single
    object. The route_key (e.g. "GET /items" or "$default") and the target
    integration are the primary inputs. authorization_type defaults to NONE;
    callers fronting protected resources should set AWS_IAM / JWT / CUSTOM.
  EOT

  type = object({
    # api_id and route_key are REQUIRED. No defaults.
    api_id    = string
    route_key = string

    target             = optional(string) # "integrations/<integration_id>"
    authorization_type = optional(string, "NONE")
    authorizer_id      = optional(string)

    tags = optional(map(string), {})
  })

  # no `default` here because api_id and route_key are required

  validation {
    condition     = contains(["NONE", "AWS_IAM", "JWT", "CUSTOM"], var.config.authorization_type)
    error_message = "config.authorization_type must be NONE, AWS_IAM, JWT, or CUSTOM."
  }

  validation {
    condition     = !contains(["JWT", "CUSTOM"], var.config.authorization_type) || var.config.authorizer_id != null
    error_message = "config.authorizer_id is required when config.authorization_type is JWT or CUSTOM."
  }
}
