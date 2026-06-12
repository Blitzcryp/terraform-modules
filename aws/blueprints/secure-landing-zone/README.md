# secure-landing-zone (blueprint)

An **account security baseline** for a PCI-DSS environment, composed entirely
from components (no atoms, no raw resources). With only a `name_prefix` it lays
down the full preventive + detective baseline an account needs before any
workload lands on it.

This is a **blueprint** (the top layer): it composes **components** via `module`
blocks only. Each capability is gated by an `enable_*` flag, and a single
bring-your-own CMK can be threaded into every component that encrypts at rest.

## What it deploys

| # | Capability | Component | Toggle | Default | PCI DSS |
|---|------------|-----------|--------|---------|---------|
| 1 | IAM account password policy | `account-baseline` | `enable_account_baseline` | on | Req 8 |
| 2 | Central KMS-encrypted audit log group + VPC flow-log role | `audit-logging` | `enable_audit_logging` | on | Req 10 |
| 3 | Multi-region, encrypted, log-file-validated CloudTrail | `cloudtrail` | `enable_cloudtrail` | on | Req 10 |
| 4 | Security Hub + AWS Config + GuardDuty + Inspector | `cspm` | `enable_cspm` | on | Req 6/10/11 |
| 5 | Findings (Security Hub/Inspector/GuardDuty) → encrypted SNS | `findings-notification` | `enable_findings_notification` | on | Req 10 |
| 6 | Baseline VPC (private-by-default subnets, flow logs on) | `secure-network` | `enable_network` | **off** | Req 1 |

The network is off by default because a landing zone may or may not own its own
VPC. Everything else is on by default so an empty `{}`-style config (just a
`name_prefix`) yields a fully compliant baseline.

### Toggles & nested config

- **`enable_account_baseline`** → IAM password policy. Tune via the nested
  `password_policy` object: `minimum_length` (default 14, PCI min 12),
  `max_age` (default 90), `reuse_prevention` (default 4). Validation enforces the
  PCI floors.
- **`enable_audit_logging`** → central CloudWatch log group (KMS-encrypted, 1y
  retention) plus a VPC flow-log delivery role. Accepts the shared `kms_key_arn`.
- **`enable_cloudtrail`** → a multi-region, encrypted, validated trail with its
  S3 store. `cloudtrail_is_organization_trail` (default false) makes it an org
  trail when run from the management account. Accepts the shared `kms_key_arn`.
- **`enable_cspm`** → the four AWS-native posture services. Inspector scans the
  resource types in `cspm_inspector_resource_types` (default `["ECR","EC2","LAMBDA"]`).
  Accepts the shared `kms_key_arn` (encrypts the Config delivery bucket).
- **`enable_findings_notification`** → an EventBridge rule routing findings to a
  KMS-encrypted SNS topic. `findings_source` (default `"all"`) selects which
  service's findings to route. It routes by **event pattern**, so it is fully
  independent of the cspm resources. Accepts the shared `kms_key_arn`.
- **`enable_network`** → a baseline VPC. Requires a non-empty `subnets` list and
  uses `vpc_cidr` (default `10.0.0.0/16`). Subnets are private unless `public = true`.

### Shared CMK

`kms_key_arn` (optional) is a bring-your-own CMK threaded into
`audit-logging`, `cloudtrail`, `cspm` and `findings-notification` — the four
components that encrypt data at rest. `account-baseline` has no encrypted store,
so it does not take a key. When `kms_key_arn` is null, each component creates and
owns its own compliant, rotation-enabled CMK.

## Architecture

```
                     ┌──────────────────────────────────────────────┐
                     │            secure-landing-zone (account)       │
                     │                                                │
  shared kms_key_arn │  ┌───────────────┐   ┌──────────────────────┐ │
  (optional, BYO) ───┼─▶│ account-       │   │ audit-logging        │ │
                     │  │ baseline       │   │ (log group + CMK +   │ │
                     │  │ (pwd policy)   │   │  flow-log role)      │ │
                     │  └───────────────┘   └──────────────────────┘ │
                     │  ┌───────────────┐   ┌──────────────────────┐ │
                     │  │ cloudtrail     │   │ cspm                 │ │
                     │  │ (multi-region  │   │ SecurityHub + Config │ │
                     │  │  trail + S3)   │   │ + GuardDuty + Inspect│ │
                     │  └───────────────┘   └──────────┬───────────┘ │
                     │  ┌───────────────┐              │ findings    │
                     │  │ secure-network │   ┌──────────▼───────────┐ │
                     │  │ (optional VPC) │   │ findings-notification│ │
                     │  └───────────────┘   │ EventBridge → SNS    │ │
                     │                       └──────────────────────┘ │
                     └──────────────────────────────────────────────┘
```

findings-notification matches findings by **event pattern**, not by ARN, so it
does not depend on the cspm component — the two are wired independently.

## Usage

```hcl
module "landing_zone" {
  source = "../.."

  config = {
    name_prefix = "paws-prod"
  }
}
```

See `examples/minimal` (defaults, no network) and `examples/full` (every
capability, a baseline VPC, a shared BYO CMK and a hardened password policy).

## PCI DSS Controls

- **Req 1** — baseline VPC with private-by-default subnets and flow logs (optional tier).
- **Req 6 / 11** — Inspector continuous vulnerability scanning, Security Hub + Config posture.
- **Req 8** — IAM account password policy (length, age, reuse).
- **Req 10** — CloudTrail, central audit log group, and findings notification pipeline.

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
| <a name="module_account_baseline"></a> [account\_baseline](#module\_account\_baseline) | ../../components/account-baseline | n/a |
| <a name="module_audit_logging"></a> [audit\_logging](#module\_audit\_logging) | ../../components/audit-logging | n/a |
| <a name="module_cloudtrail"></a> [cloudtrail](#module\_cloudtrail) | ../../components/cloudtrail | n/a |
| <a name="module_cspm"></a> [cspm](#module\_cspm) | ../../components/cspm | n/a |
| <a name="module_findings_notification"></a> [findings\_notification](#module\_findings\_notification) | ../../components/findings-notification | n/a |
| <a name="module_network"></a> [network](#module\_network) | ../../components/secure-network | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Single configuration object for the secure-landing-zone BLUEPRINT: an<br/>account-wide security baseline for a PCI-DSS environment, composed entirely<br/>from components (no atoms, no raw resources). All inputs live on this one<br/>object.<br/><br/>Secure-by-default: with only a `name_prefix` the blueprint turns on the full<br/>detective/preventive baseline — an IAM password policy (Req 8), a central<br/>KMS-encrypted audit log group + flow-log role (Req 10), a multi-region<br/>encrypted+validated CloudTrail (Req 10), the CSPM posture stack of Security<br/>Hub + AWS Config + GuardDuty + Inspector (Req 6/10/11), and a findings<br/>notification pipeline routing those findings to an encrypted SNS topic (Req<br/>10). Each capability is individually gated by an `enable_*` flag.<br/><br/>A baseline VPC (secure-network, Req 1) is OFF by default because a landing<br/>zone may or may not own networking; enable it with `enable_network` and a<br/>`subnets` list.<br/><br/>A single bring-your-own CMK (`kms_key_arn`) can be threaded into every<br/>component that accepts one (audit-logging, cloudtrail, cspm,<br/>findings-notification); otherwise each component creates its own compliant<br/>CMK. | <pre>object({<br/>    # --- Always required ---<br/>    name_prefix = string                    # base name fanned into every composed component<br/>    tags        = optional(map(string), {}) # instance tags (global tags come from provider default_tags)<br/><br/>    # --- Shared BYO CMK (optional) ---<br/>    # When set, this CMK encrypts the audit log group, the CloudTrail store, the<br/>    # AWS Config delivery bucket and the findings SNS topic. When null, each of<br/>    # those components owns and creates its own compliant CMK.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Capability: account baseline (IAM password policy, PCI DSS Req 8) ---<br/>    enable_account_baseline = optional(bool, true)<br/>    password_policy = optional(object({<br/>      minimum_length   = optional(number, 14) # PCI 8.3.6: >= 12<br/>      max_age          = optional(number, 90) # PCI 8.3.9: rotate <= 90 days<br/>      reuse_prevention = optional(number, 4)  # PCI 8.3.7: >= 4 cycles<br/>    }), {})<br/><br/>    # --- Capability: audit logging backbone (central log group + CMK, Req 10) ---<br/>    enable_audit_logging = optional(bool, true)<br/><br/>    # --- Capability: CloudTrail (multi-region encrypted validated trail, Req 10) ---<br/>    enable_cloudtrail                = optional(bool, true)<br/>    cloudtrail_is_organization_trail = optional(bool, false)<br/><br/>    # --- Capability: CSPM posture stack (Security Hub + Config + GuardDuty + Inspector) ---<br/>    enable_cspm                   = optional(bool, true)<br/>    cspm_inspector_resource_types = optional(list(string), ["ECR", "EC2", "LAMBDA"])<br/><br/>    # --- Capability: findings notification (findings -> encrypted SNS, Req 10) ---<br/>    enable_findings_notification = optional(bool, true)<br/>    findings_source              = optional(string, "all")<br/><br/>    # --- Capability: baseline VPC (secure-network, PCI DSS Req 1). OFF by default. ---<br/>    enable_network = optional(bool, false)<br/>    vpc_cidr       = optional(string, "10.0.0.0/16")<br/>    # Subnets are PRIVATE by default (public=false); a public subnet is an<br/>    # intentional, auditable choice. Required (non-empty) only when enable_network.<br/>    subnets = optional(list(object({<br/>      name              = string<br/>      cidr_block        = string<br/>      availability_zone = string<br/>      public            = optional(bool, false)<br/>    })), [])<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the secure-landing-zone blueprint, collected on a single object. Each key is null when its capability is disabled. |
<!-- END_TF_DOCS -->
