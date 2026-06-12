<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.60 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudfront_origin_access_control.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the CloudFront Origin Access Control (OAC). All inputs live<br/>on this single object. An OAC lets CloudFront sign origin requests with SigV4<br/>so a private S3 origin can be locked down to CloudFront only (no public<br/>bucket access) — the modern replacement for the legacy Origin Access Identity.<br/>Secure-by-default values (SigV4 signing, always sign) are baked into the<br/>optional() fields, so passing only the required `name` yields a compliant OAC. | <pre>object({<br/>    name        = string           # required — unique OAC name<br/>    description = optional(string) # null = provider default<br/><br/>    # --- Secure-by-default signing (locks the origin to CloudFront) ---<br/>    origin_access_control_origin_type = optional(string, "s3")<br/>    signing_behavior                  = optional(string, "always")<br/>    signing_protocol                  = optional(string, "sigv4")<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the CloudFront origin access control atom, collected on a single object. |
<!-- END_TF_DOCS -->