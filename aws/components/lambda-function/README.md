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
| <a name="module_exec_role"></a> [exec\_role](#module\_exec\_role) | ../../atoms/iam/iam-role | n/a |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../../atoms/kms/kms-key | n/a |
| <a name="module_lambda_function"></a> [lambda\_function](#module\_lambda\_function) | ../../atoms/lambda/lambda-function | n/a |
| <a name="module_log_group"></a> [log\_group](#module\_log\_group) | ../../atoms/cloudwatch/cloudwatch-log-group | n/a |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | ../../atoms/vpc/security-group | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the lambda-function component (a secure serverless function:<br/>execution IAM role + encrypted CloudWatch log group + customer-managed KMS key<br/>(created unless a BYO key is supplied) + optional dedicated VPC security group<br/>+ the Lambda function itself). All inputs live on this single object.<br/><br/>PCI-compliant defaults are baked into the optional() fields: environment<br/>variables and logs are encrypted at rest with a CMK (Req 3), X-Ray active<br/>tracing is on (Req 10), logs are retained for one year (Req 10.5/10.7), the<br/>execution role is least-privilege (CloudWatch Logs only, plus EC2 ENI perms<br/>only when a VPC is attached), and the function runs on arm64.<br/><br/>SECURITY: never put secret values in environment\_variables in plaintext.<br/>Store secrets in SSM Parameter Store / Secrets Manager and reference them at<br/>runtime (PCI DSS Req 3 / Req 8). env vars are encrypted at rest with the CMK<br/>but are still readable by anyone with lambda:GetFunction. | <pre>object({<br/>    # --- Required: the caller must decide this ---<br/>    name = string # function + role + SG + log group base name<br/><br/>    # --- Packaging ---<br/>    package_type = optional(string, "Zip") # Zip | Image<br/>    runtime      = optional(string)        # required for Zip (e.g. python3.12)<br/>    handler      = optional(string)        # required for Zip (e.g. index.handler)<br/>    filename     = optional(string)        # local deployment package (Zip)<br/>    s3_bucket    = optional(string)        # S3 deployment package bucket (Zip)<br/>    s3_key       = optional(string)        # S3 deployment package key (Zip)<br/>    image_uri    = optional(string)        # ECR image URI (Image)<br/>    layers       = optional(list(string), [])<br/><br/>    # --- Sizing / runtime ---<br/>    memory_size                    = optional(number, 128)<br/>    timeout                        = optional(number, 30)<br/>    reserved_concurrent_executions = optional(number, -1)<br/>    architectures                  = optional(list(string), ["arm64"])<br/><br/>    # --- Environment (PCI DSS Req 3) ---<br/>    environment_variables = optional(map(string), {})<br/><br/>    # --- Encryption (PCI DSS Req 3) ---<br/>    # BYO CMK encrypting env vars + logs. When null this component creates a CMK<br/>    # whose key policy authorises CloudWatch Logs in this region.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Reliability ---<br/>    dead_letter_target_arn = optional(string)<br/><br/>    # --- Observability (PCI DSS Req 10) ---<br/>    enable_xray        = optional(bool, true)<br/>    log_retention_days = optional(number, 365)<br/><br/>    # --- Networking (optional VPC attachment) ---<br/>    # When vpc_subnet_ids is set the component creates a dedicated security group<br/>    # and attaches the function to the VPC; the execution role also gains the EC2<br/>    # ENI permissions Lambda needs for VPC access.<br/>    vpc_id         = optional(string) # required when vpc_subnet_ids is set (for the SG)<br/>    vpc_subnet_ids = optional(list(string), [])<br/><br/>    # Egress rules for the function's security group. Defaults to HTTPS-only<br/>    # outbound (AWS APIs, Secrets Manager, etc.) — documented per PCI DSS Req 1.<br/>    egress_rules = optional(list(object({<br/>      description                  = string<br/>      ip_protocol                  = string<br/>      from_port                    = optional(number)<br/>      to_port                      = optional(number)<br/>      cidr_ipv4                    = optional(string)<br/>      cidr_ipv6                    = optional(string)<br/>      referenced_security_group_id = optional(string)<br/>      prefix_list_id               = optional(string)<br/>    })), [])<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the lambda-function component, collected on a single object. |
<!-- END_TF_DOCS -->