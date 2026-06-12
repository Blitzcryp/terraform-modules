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
| [aws_lambda_permission.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for a Lambda resource-based permission statement. All inputs<br/>live on this single object. The default action is the narrowest useful one<br/>(lambda:InvokeFunction). PCI DSS Req 7 (least privilege): scope each grant to<br/>a specific source via source\_arn / source\_account so a service can only<br/>invoke this function from the intended resource.<br/><br/>NOTE: aws\_lambda\_permission is NOT a taggable resource. `tags` is accepted<br/>on the config object only for API uniformity across the library and is not<br/>applied to any AWS resource. | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    function_name = string # name or ARN of the function being granted to<br/>    statement_id  = string # unique id for this permission statement<br/>    principal     = string # who is granted (e.g. events.amazonaws.com or an account id)<br/><br/>    # --- Grant scope ---<br/>    action         = optional(string, "lambda:InvokeFunction")<br/>    source_arn     = optional(string) # restrict invocation to this source resource (PCI DSS Req 7)<br/>    source_account = optional(string) # restrict invocation to this account<br/><br/>    # Accepted for API uniformity only; aws_lambda_permission is not taggable.<br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the Lambda permission atom, collected on a single object. |
<!-- END_TF_DOCS -->