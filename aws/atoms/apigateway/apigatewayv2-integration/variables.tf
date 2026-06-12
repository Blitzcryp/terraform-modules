variable "config" {
  description = <<-EOT
    Configuration for an API Gateway v2 integration. All inputs live on this
    single object. Defaults target the common case: an AWS_PROXY integration to a
    Lambda function over the internet-facing connection, using payload format 2.0.
  EOT

  type = object({
    # api_id is REQUIRED: the integration belongs to a specific API. No default.
    api_id = string

    integration_type   = optional(string, "AWS_PROXY")
    integration_uri    = optional(string) # Lambda invoke ARN for AWS_PROXY
    integration_method = optional(string, "POST")

    payload_format_version = optional(string, "2.0")
    connection_type        = optional(string, "INTERNET")

    tags = optional(map(string), {})
  })

  # no `default` here because api_id is required

  validation {
    condition     = contains(["AWS", "AWS_PROXY", "HTTP", "HTTP_PROXY", "MOCK"], var.config.integration_type)
    error_message = "config.integration_type must be one of AWS, AWS_PROXY, HTTP, HTTP_PROXY, MOCK."
  }

  validation {
    condition     = contains(["INTERNET", "VPC_LINK"], var.config.connection_type)
    error_message = "config.connection_type must be INTERNET or VPC_LINK."
  }
}
