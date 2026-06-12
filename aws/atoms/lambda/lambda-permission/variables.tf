variable "config" {
  description = <<-EOT
    Configuration for a Lambda resource-based permission statement. All inputs
    live on this single object. The default action is the narrowest useful one
    (lambda:InvokeFunction). PCI DSS Req 7 (least privilege): scope each grant to
    a specific source via source_arn / source_account so a service can only
    invoke this function from the intended resource.

    NOTE: aws_lambda_permission is NOT a taggable resource. `tags` is accepted
    on the config object only for API uniformity across the library and is not
    applied to any AWS resource.
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    function_name = string # name or ARN of the function being granted to
    statement_id  = string # unique id for this permission statement
    principal     = string # who is granted (e.g. events.amazonaws.com or an account id)

    # --- Grant scope ---
    action         = optional(string, "lambda:InvokeFunction")
    source_arn     = optional(string) # restrict invocation to this source resource (PCI DSS Req 7)
    source_account = optional(string) # restrict invocation to this account

    # Accepted for API uniformity only; aws_lambda_permission is not taggable.
    tags = optional(map(string), {})
  })

  # no `default` here because function_name, statement_id and principal are required

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.config.statement_id))
    error_message = "config.statement_id may contain only alphanumerics, hyphens and underscores."
  }

  validation {
    condition     = trimspace(var.config.principal) != ""
    error_message = "config.principal must be set (a service principal or account id)."
  }
}
