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
| <a name="module_autoscaling_group"></a> [autoscaling\_group](#module\_autoscaling\_group) | ../../atoms/ec2/autoscaling-group | n/a |
| <a name="module_instance_profile"></a> [instance\_profile](#module\_instance\_profile) | ../../atoms/iam/iam-instance-profile | n/a |
| <a name="module_kms"></a> [kms](#module\_kms) | ../../atoms/kms/kms-key | n/a |
| <a name="module_launch_template"></a> [launch\_template](#module\_launch\_template) | ../../atoms/ec2/launch-template | n/a |
| <a name="module_role"></a> [role](#module\_role) | ../../atoms/iam/iam-role | n/a |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | ../../atoms/vpc/security-group | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the autoscaling-group component (a secure-by-default EC2<br/>Auto Scaling group with its own launch template, security group, IAM role,<br/>instance profile, and encryption key). All inputs live on this single object.<br/>PCI-DSS-compliant defaults are baked in: IMDSv2 enforced (Req 2), root volume<br/>encrypted at rest with a component-created CMK unless a BYO key is supplied<br/>(Req 3), and a security group with NO public ingress — only the supplied app<br/>security groups / CIDRs / rules may reach the instances. Required fields<br/>(name, image\_id, vpc\_id, subnet\_ids) have no default, so config cannot be<br/>omitted.<br/><br/>SECURITY: no SSH key pair is wired. Attach AmazonSSMManagedInstanceCore via<br/>managed\_policy\_arns and use SSM Session Manager for access (PCI DSS Req 8 —<br/>no shared/standing credentials). | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    name       = string       # ASG / resource prefix<br/>    image_id   = string       # AMI id for the launch template<br/>    vpc_id     = string       # VPC for the instance security group<br/>    subnet_ids = list(string) # private subnets the ASG launches into<br/><br/>    # --- Instance shape ---<br/>    instance_type    = optional(string, "t3.micro")<br/>    user_data        = optional(string)<br/>    root_volume_size = optional(number, 20)<br/><br/>    # --- Sizing ---<br/>    min_size         = optional(number, 2)<br/>    max_size         = optional(number, 4)<br/>    desired_capacity = optional(number, 2)<br/><br/>    # --- Load balancer attachment ---<br/>    target_group_arns = optional(list(string), [])<br/><br/>    # --- Encryption at rest (PCI DSS Req 3) ---<br/>    # BYO CMK ARN; when null the component creates a dedicated KMS key.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Network exposure (PCI DSS Req 1) ---<br/>    allowed_security_group_ids = optional(list(string), [])<br/>    allowed_cidrs              = optional(list(string), [])<br/>    ingress_rules = optional(list(object({<br/>      description                  = string<br/>      ip_protocol                  = string<br/>      from_port                    = optional(number)<br/>      to_port                      = optional(number)<br/>      cidr_ipv4                    = optional(string)<br/>      cidr_ipv6                    = optional(string)<br/>      referenced_security_group_id = optional(string)<br/>      prefix_list_id               = optional(string)<br/>    })), [])<br/><br/>    # --- IAM (PCI DSS Req 7 / Req 8) ---<br/>    managed_policy_arns = optional(list(string), [])<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_imdsv1      = optional(bool, false) # permit IMDSv1<br/>    allow_unencrypted = optional(bool, false) # permit an unencrypted root volume<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the autoscaling-group component, collected on a single object. |
<!-- END_TF_DOCS -->