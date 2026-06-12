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

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_access_log_group"></a> [access\_log\_group](#module\_access\_log\_group) | ../../atoms/cloudwatch/cloudwatch-log-group | n/a |
| <a name="module_api"></a> [api](#module\_api) | ../../atoms/apigateway/apigatewayv2-api | n/a |
| <a name="module_integration"></a> [integration](#module\_integration) | ../../atoms/apigateway/apigatewayv2-integration | n/a |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../../atoms/kms/kms-key | n/a |
| <a name="module_route"></a> [route](#module\_route) | ../../atoms/apigateway/apigatewayv2-route | n/a |
| <a name="module_stage"></a> [stage](#module\_stage) | ../../atoms/apigateway/apigatewayv2-stage | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the http-api component: an API Gateway v2 HTTP API fronting<br/>a Lambda function, with access logging and throttling on by default. The<br/>component composes the apigatewayv2-api + apigatewayv2-integration (AWS\_PROXY<br/>to the Lambda) + N apigatewayv2-route (one per entry in `routes`) atoms, plus<br/>an encrypted CloudWatch log group for access logs and a customer-managed KMS<br/>key (created unless a BYO key is supplied).<br/><br/>PCI-compliant defaults: access logging is wired to a KMS-encrypted log group<br/>retained for one year (Req 10), and default-route throttling is enabled to<br/>protect the backend. TLS is implicit and enforced by API Gateway.<br/><br/>APPLY-TIME NOTE: API Gateway needs permission to invoke the Lambda. This<br/>component does NOT create the aws\_lambda\_permission (it would couple the<br/>component to a Lambda it does not own). The caller must add a permission<br/>granting principal apigateway.amazonaws.com invoke on the function, scoped to<br/>"<manifest.execution\_arn>/*/*" as source\_arn. The lambda-permission atom<br/>exists for this. | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    name              = string # API + log group base name<br/>    lambda_invoke_arn = string # Lambda invoke ARN the AWS_PROXY integration targets<br/><br/>    # --- Routing ---<br/>    # Route keys, e.g. ["GET /items", "POST /items"] or the catch-all "$default".<br/>    routes = optional(list(string), ["$default"])<br/><br/>    # --- CORS (empty = no CORS configuration on the API) ---<br/>    cors_allow_origins = optional(list(string), [])<br/><br/>    # --- Throttling (protect the backend; PCI hardening) ---<br/>    throttling_burst_limit = optional(number, 5000)<br/>    throttling_rate_limit  = optional(number, 10000)<br/><br/>    # --- Encryption (PCI DSS Req 3) ---<br/>    # BYO CMK for the access-log group. When null this component creates a CMK<br/>    # whose key policy authorises CloudWatch Logs in this region.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Observability (PCI DSS Req 10) ---<br/>    log_retention_days = optional(number, 365)<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the http-api component, collected on a single object. |
<!-- END_TF_DOCS -->