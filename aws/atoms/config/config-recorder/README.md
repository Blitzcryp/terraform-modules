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
| [aws_config_configuration_recorder.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder) | resource |
| [aws_config_configuration_recorder_status.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder_status) | resource |
| [aws_config_delivery_channel.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_delivery_channel) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the AWS Config configuration recorder + delivery channel +<br/>recorder status. All inputs live on this single object. This atom records<br/>resource configuration changes (PCI DSS Req 10) to a pre-existing S3 bucket<br/>using a pre-existing IAM role; it does NOT create the bucket or the role<br/>(an atom owns one logical resource group and takes dependencies by reference).<br/>PCI-compliant defaults are baked into the optional() fields. | <pre>object({<br/>    # Recorder name (also used for the delivery channel and recorder status).<br/>    name = string<br/><br/>    # Delivery target S3 bucket name. Taken as input — NOT created by this atom.<br/>    s3_bucket_name = string<br/><br/>    # ARN of the AWS Config service role. Taken as input — NOT created here.<br/>    iam_role_arn = string<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 10: record everything) ---<br/>    record_all_resources          = optional(bool, true)<br/>    include_global_resource_types = optional(bool, true)<br/><br/>    # Optional SNS topic for configuration change / compliance notifications.<br/>    sns_topic_arn = optional(string)<br/><br/>    # Kept for interface uniformity. NOTE: the AWS Config recorder / delivery<br/>    # channel / recorder-status resources do not accept tags; this is surfaced<br/>    # in the manifest but not applied to a resource.<br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the AWS Config recorder atom, collected on a single object. |
<!-- END_TF_DOCS -->