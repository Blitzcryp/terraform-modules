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
| [aws_guardduty_detector.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector) | resource |
| [aws_guardduty_detector_feature.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector_feature) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the Amazon GuardDuty detector. All inputs live on this<br/>single object. PCI-DSS-compliant defaults are baked into the optional()<br/>fields, so passing `{}` (or omitting config entirely) enables GuardDuty<br/>threat detection with the fastest finding cadence and S3 + malware<br/>protection on (PCI DSS Req 10/11 continuous monitoring). Protection<br/>features are configured via aws\_guardduty\_detector\_feature resources. | <pre>object({<br/>    enable                       = optional(bool, true)<br/>    finding_publishing_frequency = optional(string, "FIFTEEN_MINUTES")<br/><br/>    # Protection features (each maps to an aws_guardduty_detector_feature).<br/>    enable_s3_protection         = optional(bool, true)<br/>    enable_kubernetes_protection = optional(bool, false)<br/>    enable_malware_protection    = optional(bool, true)<br/><br/>    # Kept for interface uniformity. NOTE: aws_guardduty_detector_feature does<br/>    # not accept tags; tags are applied to the detector itself.<br/>    tags = optional(map(string), {})<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the GuardDuty detector atom, collected on a single object. |
<!-- END_TF_DOCS -->