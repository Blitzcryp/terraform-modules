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
| [aws_wafv2_web_acl_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the WAFv2 Web ACL association (aws\_wafv2\_web\_acl\_association).<br/>All inputs live on this single object. This atom binds an existing REGIONAL<br/>Web ACL to a regional resource (an Application Load Balancer, API Gateway<br/>stage, AppSync GraphQL API, Cognito user pool, etc.). Both ARNs are required;<br/>the caller decides them. `tags` is accepted for interface uniformity across<br/>atoms but the underlying resource is not taggable. | <pre>object({<br/>    web_acl_arn  = string # required — ARN of the WAFv2 Web ACL (REGIONAL scope)<br/>    resource_arn = string # required — ARN of the resource to protect (ALB / APIGW / ...)<br/><br/>    # Accepted for interface uniformity; aws_wafv2_web_acl_association is not taggable.<br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the WAFv2 Web ACL association atom, collected on a single object. |
<!-- END_TF_DOCS -->