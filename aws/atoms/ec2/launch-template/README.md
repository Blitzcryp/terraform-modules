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
| [aws_launch_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the EC2 launch template. All inputs live on this single<br/>object. PCI-DSS-compliant defaults are baked into the optional() fields:<br/>IMDSv2 is enforced (http\_tokens=required, PCI Req 2), the root volume is an<br/>encrypted gp3 disk (PCI Req 3), and detailed monitoring is on (PCI Req 10).<br/>Insecure choices require flipping an explicit `allow_*` escape hatch.<br/><br/>SECURITY: prefer SSM Session Manager over `key_name` SSH keys for access<br/>(PCI DSS Req 8 — no shared/standing credentials). Leave key\_name null and<br/>attach AmazonSSMManagedInstanceCore via the instance profile instead. | <pre>object({<br/>    # --- Required: the caller must decide this ---<br/>    name = string # launch template name<br/><br/>    # --- Instance shape ---<br/>    image_id                 = optional(string)             # AMI id; may be set on the ASG/instance instead<br/>    instance_type            = optional(string, "t3.micro") # default instance size<br/>    vpc_security_group_ids   = optional(list(string), [])   # SGs attached to the primary ENI<br/>    iam_instance_profile_arn = optional(string)             # instance profile ARN<br/>    key_name                 = optional(string)             # SSH key pair; prefer SSM (see SECURITY)<br/>    user_data                = optional(string)             # cloud-init; must already be base64-encoded<br/><br/>    # --- Root volume (PCI DSS Req 3: encryption at rest) ---<br/>    root_volume_size = optional(number, 20)<br/>    root_volume_type = optional(string, "gp3")<br/>    kms_key_arn      = optional(string) # CMK for the root volume; null = AWS-managed EBS key<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_imdsv1      = optional(bool, false) # permit IMDSv1 (http_tokens=optional)<br/>    allow_unencrypted = optional(bool, false) # permit an unencrypted root volume<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the launch template atom, collected on a single object. |
<!-- END_TF_DOCS -->