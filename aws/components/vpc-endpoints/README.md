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
| <a name="module_endpoint_sg"></a> [endpoint\_sg](#module\_endpoint\_sg) | ../../atoms/vpc/security-group | n/a |
| <a name="module_gateway_endpoint"></a> [gateway\_endpoint](#module\_gateway\_endpoint) | ../../atoms/vpc/vpc-endpoint | n/a |
| <a name="module_interface_endpoint"></a> [interface\_endpoint](#module\_interface\_endpoint) | ../../atoms/vpc/vpc-endpoint | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the vpc-endpoints component. All inputs live on this single<br/>object. `vpc_id` is required (the caller must decide it). PCI-DSS-compliant<br/>defaults are baked into the optional() fields: a curated set of Gateway<br/>(S3, DynamoDB) and Interface (ECR, Logs, Secrets Manager, KMS, SSM, STS,<br/>monitoring) endpoints is created so that workloads reach those AWS services<br/>privately, keeping traffic off the public internet (PCI DSS Req 1 — network<br/>segmentation). The component builds full service names as<br/>com.amazonaws.<region>.<short> using the current region. | <pre>object({<br/>    vpc_id = string # required — the caller must decide this<br/><br/>    # Where to wire the endpoints. Interface endpoints place ENIs in these<br/>    # (private) subnets; Gateway endpoints install routes in these route tables.<br/>    private_subnet_ids      = optional(list(string), [])<br/>    private_route_table_ids = optional(list(string), [])<br/><br/>    # Short service names (without the com.amazonaws.<region>. prefix). The<br/>    # defaults are the common set of AWS services a private workload needs.<br/>    gateway_services   = optional(list(string), ["s3", "dynamodb"])<br/>    interface_services = optional(list(string), ["ecr.api", "ecr.dkr", "logs", "secretsmanager", "kms", "ssm", "ssmmessages", "ec2messages", "sts", "monitoring"])<br/><br/>    # CIDRs permitted to reach the Interface endpoint ENIs on 443. Empty (the<br/>    # default) means "the VPC's own CIDR", looked up via data.aws_vpc — so only<br/>    # in-VPC traffic can use the endpoints (PCI DSS Req 1).<br/>    allowed_cidrs = optional(list(string), [])<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the vpc-endpoints component, collected on a single object. |
<!-- END_TF_DOCS -->