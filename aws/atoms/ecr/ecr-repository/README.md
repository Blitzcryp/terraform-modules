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
| [aws_ecr_lifecycle_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the ECR repository. All inputs live on this single object.<br/>PCI-DSS-compliant defaults are baked into the optional() fields, so passing<br/>only the required `name` yields a compliant repository: scan-on-push enabled<br/>(Req 6 vuln mgmt), immutable tags (image integrity), encryption at rest<br/>(Req 3), and a lifecycle policy expiring untagged images. Insecure choices<br/>require flipping an explicit `allow_*` escape hatch. | <pre>object({<br/>    name = string # required — the repository name<br/><br/>    # --- Secure-by-default controls ---<br/>    # PCI DSS Req 6: scan images for vulnerabilities on push.<br/>    scan_on_push = optional(bool, true)<br/>    # Image integrity: immutable tags prevent silent overwrite of a tag.<br/>    image_tag_mutability = optional(string, "IMMUTABLE")<br/>    # PCI DSS Req 3: encryption at rest. KMS key ARN; null = AWS-managed AES256.<br/>    kms_key_arn = optional(string)<br/>    # Lifecycle policy: expire untagged images after N days; keep last N tagged.<br/>    untagged_expiry_days = optional(number, 14)<br/>    tagged_image_count   = optional(number, 30)<br/>    # Optional repository policy JSON (resource-based access policy).<br/>    additional_repository_policy = optional(string)<br/>    force_delete                 = optional(bool, false)<br/>    tags                         = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_scan_on_push_disabled = optional(bool, false)<br/>    allow_mutable_tags          = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the ECR repository atom, collected on a single object. |
<!-- END_TF_DOCS -->