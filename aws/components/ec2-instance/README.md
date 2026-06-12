<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.60 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_instance"></a> [instance](#module\_instance) | ../../atoms/ec2/ec2-instance | n/a |
| <a name="module_instance_profile"></a> [instance\_profile](#module\_instance\_profile) | ../../atoms/iam/iam-instance-profile | n/a |
| <a name="module_kms"></a> [kms](#module\_kms) | ../../atoms/kms/kms-key | n/a |
| <a name="module_role"></a> [role](#module\_role) | ../../atoms/iam/iam-role | n/a |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | ../../atoms/vpc/security-group | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the ec2-instance component (a standalone, secure-by-default<br/>EC2 instance with its own security group, IAM role, instance profile, and<br/>encryption key). All inputs live on this single object. PCI-DSS-compliant<br/>defaults are baked in: IMDSv2 enforced (Req 2), root volume encrypted at rest<br/>with a component-created CMK unless a BYO key is supplied (Req 3), no public<br/>IP (Req 1), and a security group with NO public ingress — only the supplied<br/>app security groups / CIDRs / rules may reach the instance. Required fields<br/>(name, ami, vpc\_id, subnet\_id) have no default, so config cannot be omitted.<br/><br/>SECURITY: no SSH key pair is wired. Attach AmazonSSMManagedInstanceCore via<br/>managed\_policy\_arns and use SSM Session Manager for access (PCI DSS Req 8 —<br/>no shared/standing credentials). | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    name      = string # instance name / resource prefix<br/>    ami       = string # AMI id to launch<br/>    vpc_id    = string # VPC for the instance security group<br/>    subnet_id = string # subnet the ENI lands in<br/><br/>    # --- Instance shape ---<br/>    instance_type    = optional(string, "t3.micro")<br/>    user_data        = optional(string)<br/>    root_volume_size = optional(number, 20)<br/><br/>    # --- Encryption at rest (PCI DSS Req 3) ---<br/>    # BYO CMK ARN; when null the component creates a dedicated KMS key.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Network exposure (PCI DSS Req 1) ---<br/>    # Instance ingress is allowed ONLY from these app security groups / CIDRs, or<br/>    # via explicit ingress_rules. Empty => a security group with no ingress at all.<br/>    allowed_security_group_ids = optional(list(string), [])<br/>    allowed_cidrs              = optional(list(string), [])<br/>    ingress_rules = optional(list(object({<br/>      description                  = string<br/>      ip_protocol                  = string<br/>      from_port                    = optional(number)<br/>      to_port                      = optional(number)<br/>      cidr_ipv4                    = optional(string)<br/>      cidr_ipv6                    = optional(string)<br/>      referenced_security_group_id = optional(string)<br/>      prefix_list_id               = optional(string)<br/>    })), [])<br/><br/>    # --- IAM (PCI DSS Req 7 / Req 8) ---<br/>    # Managed policy ARNs attached to the instance role (e.g. SSM core access).<br/>    managed_policy_arns = optional(list(string), [])<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_imdsv1      = optional(bool, false) # permit IMDSv1<br/>    allow_unencrypted = optional(bool, false) # permit an unencrypted root volume<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the ec2-instance component, collected on a single object. |
<!-- END_TF_DOCS -->