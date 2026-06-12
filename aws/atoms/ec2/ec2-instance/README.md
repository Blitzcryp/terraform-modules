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
| [aws_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the EC2 instance. All inputs live on this single object.<br/>PCI-DSS-compliant defaults are baked into the optional() fields: IMDSv2 is<br/>enforced (PCI Req 2), the root volume is encrypted at rest (PCI Req 3), no<br/>public IP is assigned (PCI Req 1), detailed monitoring and EBS optimization<br/>are on. Insecure choices require flipping an explicit `allow_*` escape hatch.<br/><br/>SECURITY: prefer SSM Session Manager over `key_name` SSH keys for access<br/>(PCI DSS Req 8 — no shared/standing credentials). Leave key\_name null and<br/>attach AmazonSSMManagedInstanceCore via the instance profile instead. | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    ami                    = string       # AMI id to launch<br/>    subnet_id              = string       # subnet the ENI lands in<br/>    vpc_security_group_ids = list(string) # SGs attached to the primary ENI<br/><br/>    # --- Instance shape ---<br/>    instance_type        = optional(string, "t3.micro")<br/>    iam_instance_profile = optional(string) # instance profile NAME (not ARN)<br/>    key_name             = optional(string) # SSH key pair; prefer SSM (see SECURITY)<br/>    user_data            = optional(string) # cloud-init; rendered base64 by the provider<br/><br/>    # --- Root volume (PCI DSS Req 3: encryption at rest) ---<br/>    root_volume_size = optional(number, 20)<br/>    root_volume_type = optional(string, "gp3")<br/>    kms_key_arn      = optional(string) # CMK for root + extra volumes; null = AWS-managed EBS key<br/><br/>    # Additional EBS data volumes. Each is encrypted by default (uses kms_key_arn).<br/>    ebs_block_devices = optional(list(object({<br/>      device_name = string<br/>      volume_size = optional(number, 20)<br/>      volume_type = optional(string, "gp3")<br/>      iops        = optional(number)<br/>      throughput  = optional(number)<br/>      encrypted   = optional(bool, true)<br/>    })), [])<br/><br/>    # --- Secure-by-default toggles ---<br/>    monitoring                  = optional(bool, true)  # detailed CloudWatch monitoring (PCI Req 10)<br/>    ebs_optimized               = optional(bool, true)  # dedicated EBS throughput<br/>    associate_public_ip_address = optional(bool, false) # PCI Req 1: stay private<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_imdsv1      = optional(bool, false) # permit IMDSv1 (http_tokens=optional)<br/>    allow_unencrypted = optional(bool, false) # permit an unencrypted root volume<br/>    allow_public_ip   = optional(bool, false) # permit associate_public_ip_address=true<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the EC2 instance atom, collected on a single object. |
<!-- END_TF_DOCS -->