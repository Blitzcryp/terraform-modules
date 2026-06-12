# fargate-web-service (blueprint)

A full-cycle, **PCI-secure-by-default** containerised web service on AWS Fargate.
This is a **blueprint** — the top layer of the library — so it composes
**components only** (via `module` blocks), never atoms or raw `aws_*` resources.
It takes a single `config` object and returns a single `manifest` object.

One call stands up the always-on core (network resolution, encrypted audit
logging, ECS cluster, a public TLS-terminating ALB, the Fargate service) plus a
set of **optional tiers** toggled with explicit `enable_*` flags.

## What it composes

| # | Component | When | Purpose |
|---|-----------|------|---------|
| 1 | `secure-network` | `create_network = true` | Creates the VPC + public/private subnets (flow logs on). Otherwise the caller's `vpc_id` / subnet ids are used. |
| 2 | `audit-logging` | always | App CloudWatch log group + CMK (PCI DSS Req 3 & 10). |
| 3 | `ecs-cluster` | always | Fargate cluster with Container Insights + encrypted Exec logging. |
| 4 | `ecr` | `enable_ecr = true` (default) | Scan-on-push, immutable, KMS-encrypted image registry. |
| 5 | `acm` | `domain_name` set | DNS-validated, ISSUED TLS certificate. |
| 6 | `alb` | always | **Internet-facing** Application Load Balancer — the single, intentional public entrypoint. Always terminates TLS. |
| 7 | `waf` | `enable_waf = true` (default) | WAFv2 Web ACL (AWS baseline rule groups) associated to the ALB. |
| 8 | `ecs-service` | always | The app task in **private** subnets, no public IP, registered with the ALB target group. |
| 9 | `rds-aurora` / `rds-aurora-serverless` | `enable_database = true` | Aurora cluster in private subnets; reachable **only** from the app security group. |
| 10 | `elasticache` | `enable_cache = true` | Redis tier in private subnets; reachable **only** from the app security group. |
| 11 | `secrets-manager` | `enable_secrets = true` (default) | CMK-encrypted vault for app secrets. |
| 12 | `dns-record` | `domain_name` set | Alias A record pointing the domain at the ALB. |

## Architecture

```
                          Internet
                             │  HTTPS :443  (HTTP :80 -> 301 redirect)
                             ▼
                    ┌──────────────────┐      ┌──────────────┐
                    │   WAFv2 Web ACL  │◄─────│ ACM cert     │ (domain) or BYO
                    │   (optional)     │      │ certificate  │
                    └────────┬─────────┘      └──────────────┘
                             │ associated
                             ▼
        public subnets ┌──────────────┐   access logs   ┌──────────────┐
                       │     ALB      │────────────────► │ S3 (locked)  │
                       │ internet-    │                  └──────────────┘
                       │ facing       │
                       └──────┬───────┘
                              │ target group (HTTP, container port)
                              │ SG: ALB SG only
                              ▼
       private subnets ┌──────────────┐      awslogs      ┌──────────────┐
                       │ ECS Fargate  │─────────────────► │ CloudWatch   │
                       │ service/task │                   │ (KMS) + CMK  │
                       │ no public IP │                   └──────────────┘
                       └───┬──────┬───┘
              app SG only  │      │  app SG only
                           ▼      ▼
              ┌────────────────┐ ┌────────────────┐
              │ Aurora (RDS)   │ │ ElastiCache    │   ┌──────────────────┐
              │ (optional)     │ │ Redis (opt.)   │   │ Secrets Manager  │
              │ private        │ │ private        │   │ vault (optional) │
              └────────────────┘ └────────────────┘   └──────────────────┘
```

## Optional tiers in detail

- **Network (`create_network`)** — default `false`: bring your own `vpc_id`,
  `public_subnet_ids`, `private_subnet_ids` (≥2 of each, across AZs). Set `true`
  to compose `secure-network` from `vpc_cidr` + a `subnets` list (each with an
  AZ and a `public` flag). The blueprint resolves `local.vpc_id` /
  `public_subnet_ids` / `private_subnet_ids` from whichever source is active.
- **Domain / TLS** — the ALB **always** terminates TLS (PCI DSS Req 4; the `alb`
  component has no plain-HTTP escape hatch). Provide a certificate one of two
  ways: set `domain_name` (+ `hosted_zone_id`) to have ACM issue a DNS-validated
  cert and add an alias record, **or** set `certificate_arn` to bring your own.
- **ECR (`enable_ecr`)** — default on: a scanning-enabled, KMS-encrypted repo for
  the app image.
- **WAF (`enable_waf`)** — default on: a regional Web ACL associated to the ALB.
- **Database (`enable_database`)** — default off: `rds-aurora` (provisioned) or
  `rds-aurora-serverless` (when `database.serverless = true`). Private subnets;
  DB-port ingress allowed only from the ECS service security group.
- **Cache (`enable_cache`)** — default off: encrypted Redis; ingress only from the
  ECS service security group.
- **Secrets (`enable_secrets`)** — default on: a Secrets Manager vault (values are
  populated out-of-band, never in Terraform).

## Wiring / security notes (apply-time)

- **ALB is intentionally public.** `internal = false` + `allow_internet_facing`
  and `0.0.0.0/0` ingress on the listener ports + `allow_public_ingress` are set
  deliberately — a web service needs a public entrypoint. This is the only public
  surface; WAF (when on) sits in front and tasks stay private.
- **Service ↔ ALB.** The ECS service security group permits ingress **only** from
  the ALB security group on the container port. Tasks get no public IP and live in
  private subnets.
- **Service ↔ DB / cache.** The DB and cache security groups allow ingress **only**
  from the ECS service security group (`allowed_security_group_ids = [app SG]`).
- **TLS termination.** TLS terminates at the ALB; the backend leg to the task
  inside the private VPC is HTTP on the container port, so the blueprint authors a
  matching HTTP target group (the `alb` default HTTPS:443 health check would
  otherwise fail against the app).
- **Secrets handling.** `environment` carries **non-secret** env vars only. Inject
  secret material via the container `secrets` block referencing the
  `secrets-manager` ARNs or the RDS master-user secret (surfaced on the manifest as
  `database_master_secret_arn`). Never put secrets in `environment` (PCI DSS Req
  3 / Req 8).

## Tagging

Global org tags (`Environment`, `Project`, `Owner`, `Compliance`, …) come from the
consumer's provider `default_tags` — set once, never threaded through module
calls (see `aws/examples/global-config/`). This blueprint hardcodes only its own
`Module = blueprints/fargate-web-service` identity tag and merges `config.tags`,
threading the result into every composed component.

## PCI DSS Controls

- **Req 1** — tasks in private subnets, no public IP; DB/cache reachable only from
  the app SG; ALB is the single, documented public entrypoint.
- **Req 3** — encryption at rest everywhere (logs, ECR, RDS, cache, secrets) via
  customer-managed KMS keys.
- **Req 4** — TLS terminated at the ALB (HTTPS:443, HTTP→HTTPS redirect).
- **Req 6 / 6.6** — ECR scan-on-push + Inspector; WAFv2 in front of the ALB.
- **Req 8** — secret material via Secrets Manager / RDS-managed master secret,
  never plaintext.
- **Req 10** — VPC flow logs, ALB access logs, WAF request logs, app + cluster
  CloudWatch logs with ≥1-year retention.

## Examples

- [`examples/minimal`](examples/minimal) — app only: BYO VPC + subnets + BYO TLS
  cert, no domain/db/cache; `default_tags` set once on the provider.
- [`examples/full`](examples/full) — `create_network` + domain (ACM) + database +
  cache + WAF + ECR + secrets, showing the globals / `default_tags` pattern.

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
| <a name="module_alb"></a> [alb](#module\_alb) | ../../components/alb | n/a |
| <a name="module_audit_logging"></a> [audit\_logging](#module\_audit\_logging) | ../../components/audit-logging | n/a |
| <a name="module_cache"></a> [cache](#module\_cache) | ../../components/elasticache | n/a |
| <a name="module_certificate"></a> [certificate](#module\_certificate) | ../../components/acm | n/a |
| <a name="module_database"></a> [database](#module\_database) | ../../components/rds-aurora | n/a |
| <a name="module_database_serverless"></a> [database\_serverless](#module\_database\_serverless) | ../../components/rds-aurora-serverless | n/a |
| <a name="module_dns_record"></a> [dns\_record](#module\_dns\_record) | ../../components/dns-record | n/a |
| <a name="module_ecr"></a> [ecr](#module\_ecr) | ../../components/ecr | n/a |
| <a name="module_ecs_cluster"></a> [ecs\_cluster](#module\_ecs\_cluster) | ../../components/ecs-cluster | n/a |
| <a name="module_ecs_service"></a> [ecs\_service](#module\_ecs\_service) | ../../components/ecs-service | n/a |
| <a name="module_network"></a> [network](#module\_network) | ../../components/secure-network | n/a |
| <a name="module_secrets"></a> [secrets](#module\_secrets) | ../../components/secrets-manager | n/a |
| <a name="module_waf"></a> [waf](#module\_waf) | ../../components/waf | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Single configuration object for the fargate-web-service BLUEPRINT: a full,<br/>PCI-secure-by-default containerised web service on AWS Fargate, composed<br/>entirely from components. All inputs live on this one object.<br/><br/>Secure-by-default: tasks run in PRIVATE subnets with no public IP, logs and<br/>data are encrypted at rest, WAF + ECR scanning + secrets management are on by<br/>default, and the only public entrypoint is the (intentionally internet-facing)<br/>ALB. Optional tiers (network creation, custom domain/TLS, database, cache,<br/>secrets, ECR) are toggled with explicit enable flags and nested config.<br/><br/>SECURITY: never put secret values in `environment` (plaintext env vars). Use<br/>`enable_secrets` + reference the resulting secret ARNs in your task's<br/>container `secrets` block, or surface the DB master-user secret (PCI DSS<br/>Req 3 / Req 8). | <pre>object({<br/>    # --- Always required ---<br/>    name_prefix = string                    # base name for every composed resource<br/>    tags        = optional(map(string), {}) # instance tags (global tags come from provider default_tags)<br/><br/>    # --- Application (container) ---<br/>    container_image    = string # required — image URI (e.g. an ECR repo URI:tag)<br/>    container_name     = optional(string, "app")<br/>    container_port     = optional(number, 8080)<br/>    desired_count      = optional(number, 2) # >1 for availability<br/>    cpu                = optional(string, "512")<br/>    memory             = optional(string, "1024")<br/>    environment        = optional(map(string), {}) # NON-SECRET env vars only<br/>    execution_role_arn = optional(string)          # pass-through to the task definition<br/>    task_role_arn      = optional(string)          # pass-through to the task definition<br/><br/>    # --- Network: bring-your-own (default) or create a secure-network ---<br/>    create_network = optional(bool, false)<br/>    # BYO (create_network = false): supply existing ids.<br/>    vpc_id             = optional(string)<br/>    public_subnet_ids  = optional(list(string), [])<br/>    private_subnet_ids = optional(list(string), [])<br/>    # Create (create_network = true): a secure-network is composed.<br/>    vpc_cidr = optional(string, "10.0.0.0/16")<br/>    subnets = optional(list(object({<br/>      name              = string<br/>      cidr_block        = string<br/>      availability_zone = string<br/>      public            = optional(bool, false)<br/>    })), [])<br/><br/>    # --- Domain / TLS. The ALB ALWAYS terminates TLS at the edge (PCI DSS Req 4;<br/>    # the alb component has no plain-HTTP escape hatch), so a certificate is<br/>    # mandatory. Provide it ONE of two ways:<br/>    #   - set domain_name (+ hosted_zone_id): the blueprint composes acm to issue<br/>    #     a DNS-validated cert and adds an alias A record pointing at the ALB, or<br/>    #   - set certificate_arn: bring your own ACM cert (no DNS record is created).<br/>    domain_name     = optional(string)<br/>    hosted_zone_id  = optional(string)<br/>    certificate_arn = optional(string) # BYO cert; used when domain_name is unset<br/><br/>    # --- Optional tier: ECR repository for the app image (PCI DSS Req 6) ---<br/>    enable_ecr = optional(bool, true)<br/><br/>    # --- Optional tier: WAF on the ALB (PCI DSS Req 6.6) ---<br/>    enable_waf = optional(bool, true)<br/><br/>    # --- Optional tier: Aurora database (private; reachable only from the app SG) ---<br/>    enable_database = optional(bool, false)<br/>    database = optional(object({<br/>      engine         = optional(string, "aurora-postgresql")<br/>      serverless     = optional(bool, false)<br/>      instance_class = optional(string, "db.r6g.large")<br/>      instance_count = optional(number, 2)<br/>      min_capacity   = optional(number, 0.5) # serverless v2 ACUs<br/>      max_capacity   = optional(number, 4)   # serverless v2 ACUs<br/>    }), {})<br/><br/>    # --- Optional tier: ElastiCache Redis (private; reachable only from the app SG) ---<br/>    enable_cache = optional(bool, false)<br/>    cache = optional(object({<br/>      node_type          = optional(string, "cache.t4g.medium")<br/>      num_cache_clusters = optional(number, 2)<br/>    }), {})<br/><br/>    # --- Optional tier: Secrets Manager vault for app secrets (PCI DSS Req 3/8) ---<br/>    enable_secrets = optional(bool, true)<br/>    secrets = optional(map(object({<br/>      description         = optional(string)<br/>      rotation_lambda_arn = optional(string)<br/>      rotation_days       = optional(number, 30)<br/>    })), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the fargate-web-service blueprint, collected on a single object. |
<!-- END_TF_DOCS -->
