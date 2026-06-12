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
| [aws_iam_openid_connect_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the IAM OIDC identity provider. All inputs live on this<br/>single object. The caller supplies the required `url` and `client_id_list`<br/>(audience). AWS manages thumbprints for IAM OIDC providers pointing at<br/>well-known IdPs, so `thumbprint_list` may be left empty. | <pre>object({<br/>    # url is REQUIRED: the OIDC issuer URL (e.g.<br/>    # https://token.actions.githubusercontent.com). No safe default.<br/>    url = string<br/>    # client_id_list is REQUIRED: the audience(s) (aud) accepted from the IdP.<br/>    client_id_list = list(string)<br/><br/>    thumbprint_list = optional(list(string), [])<br/>    tags            = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the IAM OIDC provider atom, collected on a single object. |
<!-- END_TF_DOCS -->