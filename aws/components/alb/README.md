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
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_access_logs_bucket"></a> [access\_logs\_bucket](#module\_access\_logs\_bucket) | ../../atoms/s3/s3-bucket | n/a |
| <a name="module_alb"></a> [alb](#module\_alb) | ../../atoms/alb/alb | n/a |
| <a name="module_listeners"></a> [listeners](#module\_listeners) | ../../atoms/alb/lb-listener | n/a |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | ../../atoms/vpc/security-group | n/a |
| <a name="module_target_groups"></a> [target\_groups](#module\_target\_groups) | ../../atoms/alb/lb-target-group | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [terraform_data.tls_guard](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the alb component: an Application Load Balancer with its own<br/>dedicated security group, one or more listeners, one or more target groups, and<br/>(when logging is enabled and no BYO bucket is supplied) a dedicated, locked-down<br/>S3 access-log bucket. All inputs live on this single object.<br/><br/>PCI-DSS-compliant defaults are baked into the optional() fields, so supplying<br/>only the required fields yields a compliant, INTERNAL load balancer that:<br/>  - terminates TLS with a TLS1.2+ policy on :443 (when certificate\_arn is set),<br/>  - redirects :80 -> :443,<br/>  - restricts SG ingress to the VPC CIDR,<br/>  - ships access logs to S3 (PCI DSS Req 10).<br/>Insecure choices require flipping an explicit `allow_*` escape hatch. | <pre>object({<br/>    name       = string       # required — base name for the ALB and its child resources<br/>    vpc_id     = string       # required — VPC the ALB and SG live in<br/>    subnet_ids = list(string) # required — at least two subnets across AZs<br/><br/>    # --- Exposure (PCI DSS Req 1: limit inbound/outbound) ---<br/>    internal = optional(bool, true) # not internet-facing by default<br/>    # ESCAPE HATCH: passthrough to the alb atom; permits internal=false.<br/>    allow_internet_facing = optional(bool, false)<br/><br/>    # --- TLS (PCI DSS Req 4: encrypt transmission) ---<br/>    # ARN of an ACM certificate for the HTTPS listener. Required for the default<br/>    # HTTPS:443 listener; may be omitted only if the caller supplies a custom<br/>    # `listeners` list that contains no HTTPS listener.<br/>    certificate_arn = optional(string)<br/><br/>    # --- Listeners --------------------------------------------------------<br/>    # When null (default), the component creates the canonical secure pair:<br/>    #   - HTTPS:443 -> forward to the first target group<br/>    #   - HTTP:80   -> redirect to HTTPS:443<br/>    # Override to author your own set. Each entry maps to one lb-listener atom.<br/>    listeners = optional(list(object({<br/>      port            = number<br/>      protocol        = optional(string, "HTTPS")<br/>      certificate_arn = optional(string) # falls back to config.certificate_arn<br/>      ssl_policy      = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")<br/>      default_action = optional(object({<br/>        type             = optional(string, "forward")<br/>        target_group_key = optional(number) # index into target_groups for forward<br/>        redirect = optional(object({<br/>          port        = optional(string, "443")<br/>          protocol    = optional(string, "HTTPS")<br/>          status_code = optional(string, "HTTP_301")<br/>        }))<br/>      }), {})<br/>      allow_insecure_http = optional(bool, false)<br/>    })))<br/><br/>    # --- Target groups ----------------------------------------------------<br/>    # When null (default), the component creates a single HTTPS:443 target group.<br/>    target_groups = optional(list(object({<br/>      name     = string<br/>      port     = number<br/>      protocol = optional(string, "HTTPS")<br/>      health_check = optional(object({<br/>        path                = optional(string, "/")<br/>        port                = optional(string, "traffic-port")<br/>        protocol            = optional(string, "HTTPS")<br/>        matcher             = optional(string, "200")<br/>        interval            = optional(number, 30)<br/>        timeout             = optional(number, 5)<br/>        healthy_threshold   = optional(number, 3)<br/>        unhealthy_threshold = optional(number, 3)<br/>      }), {})<br/>    })))<br/><br/>    # --- Security group ingress ------------------------------------------<br/>    # CIDRs allowed to reach the ALB. When null (default) ingress is restricted<br/>    # to the VPC CIDR (looked up from vpc_id). Setting public CIDRs (0.0.0.0/0)<br/>    # also requires allow_public_ingress=true (passed to the SG atom).<br/>    ingress_cidrs = optional(list(string))<br/>    # ESCAPE HATCH: passthrough to the security-group atom; permits public ingress.<br/>    allow_public_ingress = optional(bool, false)<br/><br/>    # --- Access logging (PCI DSS Req 10) ---------------------------------<br/>    enable_access_logs = optional(bool, true)<br/>    # BYO access-log bucket NAME. When set, the component does NOT create a bucket<br/>    # and assumes the caller has attached the required ELB log-delivery policy.<br/>    access_logs_bucket = optional(string)<br/>    access_logs_prefix = optional(string)<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the alb component, collected on a single object. |
<!-- END_TF_DOCS -->