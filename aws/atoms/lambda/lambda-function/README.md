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
| [aws_lambda_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the Lambda function atom. All inputs live on this single<br/>object. PCI-DSS-compliant defaults are baked into the optional() fields:<br/>environment variables are encrypted at rest with a CMK (Req 3), X-Ray active<br/>tracing is on (Req 10), and the function runs on arm64. Insecure choices<br/>(e.g. unencrypted env vars) require flipping an explicit `allow_*` escape<br/>hatch.<br/><br/>SECURITY: never put secret values in environment\_variables in plaintext.<br/>Store secrets in SSM Parameter Store / Secrets Manager and reference them at<br/>runtime (e.g. resolve them inside the handler, or via the<br/>`secretsmanager`/`ssm` extensions). environment\_variables are encrypted at<br/>rest with the CMK but are still readable by anyone with lambda:GetFunction. | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    function_name = string # unique function name<br/>    role          = string # execution role ARN (PCI DSS Req 7/8)<br/><br/>    # --- Packaging ---<br/>    package_type = optional(string, "Zip") # Zip | Image<br/>    runtime      = optional(string)        # required for Zip (e.g. python3.12); unused for Image<br/>    handler      = optional(string)        # required for Zip (e.g. index.handler); unused for Image<br/>    filename     = optional(string)        # local deployment package (Zip)<br/>    s3_bucket    = optional(string)        # S3 deployment package bucket (Zip)<br/>    s3_key       = optional(string)        # S3 deployment package key (Zip)<br/>    image_uri    = optional(string)        # ECR image URI (Image)<br/>    layers       = optional(list(string), [])<br/><br/>    # --- Sizing / runtime ---<br/>    memory_size                    = optional(number, 128)<br/>    timeout                        = optional(number, 3)<br/>    reserved_concurrent_executions = optional(number, -1) # -1 = unreserved<br/>    architectures                  = optional(list(string), ["arm64"])<br/><br/>    # --- Environment (PCI DSS Req 3: encrypt env vars at rest) ---<br/>    environment_variables = optional(map(string), {})<br/>    kms_key_arn           = optional(string) # CMK encrypting env vars; required when env vars set unless allow_unencrypted_env=true<br/><br/>    # --- Networking (optional VPC attachment) ---<br/>    vpc_subnet_ids         = optional(list(string), [])<br/>    vpc_security_group_ids = optional(list(string), [])<br/><br/>    # --- Reliability ---<br/>    dead_letter_target_arn = optional(string) # SQS/SNS ARN for failed async invocations<br/><br/>    # --- Observability (PCI DSS Req 10) ---<br/>    enable_xray = optional(bool, true) # X-Ray active tracing<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    # Permit setting environment_variables without a CMK (env vars use the<br/>    # AWS-managed default Lambda key instead of a customer-managed key).<br/>    allow_unencrypted_env = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the Lambda function atom, collected on a single object. |
<!-- END_TF_DOCS -->