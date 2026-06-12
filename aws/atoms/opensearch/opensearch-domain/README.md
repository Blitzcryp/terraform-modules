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
| [aws_opensearch_domain.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/opensearch_domain) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the OpenSearch domain. All inputs live on this single object.<br/>PCI-DSS-compliant defaults are baked into the optional() fields, so the caller<br/>only has to supply the required `domain_name`: encryption at rest is on, node-to-node<br/>encryption is on, HTTPS is enforced with TLS 1.2, and fine-grained access control<br/>is on with an IAM master user. Insecure choices require flipping an explicit<br/>`allow_*` escape hatch (grep-able, auditable). | <pre>object({<br/>    # --- Required: the caller must decide this ---<br/>    domain_name = string # required — the OpenSearch domain name<br/><br/>    # --- Engine / sizing ---<br/>    engine_version = optional(string, "OpenSearch_2.11")<br/>    instance_type  = optional(string, "t3.small.search")<br/>    instance_count = optional(number, 2)<br/>    zone_awareness = optional(bool, true) # spread data nodes across AZs<br/>    volume_size    = optional(number, 20) # EBS GiB per data node<br/><br/>    # --- Encryption at rest (PCI DSS Req 3) ---<br/>    encrypt_at_rest = optional(bool, true) # PCI DSS Req 3<br/>    # BYO CMK ARN; when null AWS uses the aws/es service key (still encrypted).<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Encryption in transit between nodes (PCI DSS Req 4) ---<br/>    node_to_node_encryption = optional(bool, true)<br/><br/>    # --- Network exposure (PCI DSS Req 1) ---<br/>    # When subnet_ids is non-empty the domain is placed inside the VPC (no public<br/>    # endpoint). security_group_ids gate access at the ENI.<br/>    vpc_subnet_ids         = optional(list(string), [])<br/>    vpc_security_group_ids = optional(list(string), [])<br/><br/>    # --- Fine-grained access control (PCI DSS Req 7/8) ---<br/>    # IAM master user by default (no password ever stored). Supplying master_user_arn<br/>    # sets the master role; null still enables FGAC with internal DB disabled.<br/>    master_user_arn = optional(string)<br/><br/>    # --- Audit / slow-log delivery (PCI DSS Req 10) ---<br/>    # When set, audit + error + search/index slow logs are published to this group.<br/>    cloudwatch_log_group_arn = optional(string)<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_unencrypted    = optional(bool, false) # permit encrypt_at_rest.enabled=false<br/>    allow_plaintext_node = optional(bool, false) # permit node_to_node_encryption.enabled=false<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the OpenSearch domain atom, collected on a single object. |
<!-- END_TF_DOCS -->