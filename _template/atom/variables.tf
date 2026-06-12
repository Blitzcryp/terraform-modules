# ONE input variable: `config`, an object. No loose top-level variables.
# Secure controls use optional(type, secure-default). Required inputs (name, vpc_id)
# are plain-typed fields with no default. Validate via validation blocks on var.config.

variable "config" {
  description = "All inputs for this module. PCI-compliant defaults baked into optional() fields."
  type = object({
    # name              = string                  # required — no default
    # <secure_control>  = optional(bool, true)    # secure default
    # allow_<insecure>  = optional(bool, false)   # ESCAPE HATCH (grep-able)
    tags = optional(map(string), {})
  })
  default = {} # drop this if any field is required

  # validation {
  #   condition     = <check on var.config.field>
  #   error_message = "config.<field> ..."
  # }
}
