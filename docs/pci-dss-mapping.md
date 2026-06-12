# PCI DSS v4.0 — Master Control Matrix

> Companion to [`CONVENTIONS.md`](../CONVENTIONS.md) and each module's
> **PCI DSS Controls** README section.

## How the design maps to PCI DSS intent

PCI DSS v4.0 expresses most technical controls as an *intent* ("protect stored
account data", "restrict access to the least needed") plus a defined approach.
This library encodes those intents two ways:

- **Secure by default = the control is on with the compliant value.** A caller
  who sets nothing gets the PCI-aligned resource (rotation on, encryption on,
  public access blocked, retention >= 1 year, least-privilege policy).
- **Auditable escape hatch = relaxing a control is intentional and grep-able.**
  Weakening a default requires flipping an explicit `allow_*` variable, which a
  `lifecycle.precondition` enforces and which leaves a searchable trail. This
  preserves PCI's expectation that any deviation be *documented and justified*.

The matrix below maps the relevant PCI DSS v4.0 requirement families to the
module control that enforces them, the `config` field/default that carries the
control, and the escape hatch that relaxes it. Per `CONVENTIONS.md` §4/§4a,
every atom now takes a single `config` object input and emits a single
`manifest` object output, so controls are referenced as `config.<field>` and
the field names below are verified against each atom's `variables.tf`.

## Control matrix

### Requirement 1 — Install and maintain network security controls (segmentation)

| PCI v4.0 (family) | Intent (1 line) | Module / control | `config` field & default | Escape hatch |
|---|---|---|---|---|
| Req 1.2–1.3 | Restrict inbound/outbound to only what is necessary; segment the CDE. | `atoms/security-group` — no implicit allow rules | `config.ingress_rules` / `config.egress_rules` default to `[]`; no `0.0.0.0/0` ingress; every rule needs a `description` | `config.allow_public_ingress = true` to permit an open CIDR; `config.allow_public_admin_ports = true` to open admin ports |
| Req 1.3.2 | System components in the CDE should not be directly reachable from untrusted networks. | `atoms/subnet` — no auto-assigned public IPs | `config.map_public_ip_on_launch = false` | `config.allow_auto_public_ip = true` to enable auto public IP |

### Requirement 3 — Protect stored account data (encryption at rest)

| PCI v4.0 (family) | Intent (1 line) | Module / control | `config` field & default | Escape hatch |
|---|---|---|---|---|
| Req 3.5 / 3.6 / 3.7 | Render stored data unreadable; manage cryptographic keys, including rotation. | `atoms/kms-key` — annual rotation, least-privilege default policy, 30-day deletion window | `config.enable_key_rotation = true`, `config.deletion_window_in_days = 30` | `config.allow_rotation_disabled = true` |
| Req 3.5 | Stored account data must be protected (encrypted) wherever stored. | `atoms/s3-bucket` — SSE enforced, KMS-backed | `config.enable_encryption = true` (+ `config.kms_key_arn` input; `null` = AWS-managed `aws:kms`) | `config.allow_unencrypted = true` |
| Req 3.5 / 10.5 | Logs may contain sensitive data; encrypt them at rest. | `atoms/cloudwatch-log-group` — KMS-encrypted log group | `config.kms_key_arn` required by default (`null` rejected unless escaped) | `config.allow_unencrypted = true` |

### Requirement 7 — Restrict access by business need to know (least privilege)

| PCI v4.0 (family) | Intent (1 line) | Module / control | `config` field & default | Escape hatch |
|---|---|---|---|---|
| Req 7.2 / 7.3 | Grant only the access an identity needs; deny by default. | `atoms/iam-role` — no admin/wildcard managed or inline policy attached | `config.managed_policy_arns = []`, `config.inline_policies = {}` (each validated as JSON) | `config.allow_admin_policy = true` |
| Req 7.2.5 | Trust relationships scoped to specific principals/services. | `atoms/iam-role` — caller must declare who may assume the role | `config.assume_role_policy` (required, no default; validated as JSON) | n/a — the trust policy is caller-supplied; scope it to specific principals (no `Principal = "*"`) |

### Requirement 8 — Identify users and authenticate access

| PCI v4.0 (family) | Intent (1 line) | Module / control | `config` field & default | Escape hatch |
|---|---|---|---|---|
| Req 8.2 / 8.3 | Unique identification; no shared/static long-lived credentials where avoidable. | `atoms/iam-role` — role assumption (temporary STS credentials) over IAM users/keys | role-based model is the only path; `config.max_session_duration = 3600` | n/a — no escape hatch; the field is hard-validated to 3600–43200s (1–12h), the AWS max |
| Req 8.4 / 8.5 (org-level) | MFA and authentication policy. | **Out of module scope** — enforced by org SCPs / IAM account policy / IdP | n/a | n/a — handled by org controls, not Terraform atoms |

### Requirement 10 — Log and monitor all access

| PCI v4.0 (family) | Intent (1 line) | Module / control | `config` field & default | Escape hatch |
|---|---|---|---|---|
| Req 10.2 / 10.3 | Record access to network resources and the CDE. | `atoms/vpc` — VPC Flow Logs enabled to a log destination | `config.enable_flow_logs = true` (delivers to CloudWatch Logs / S3 via `config.flow_log_destination_*`) | `config.allow_flow_logs_disabled = true` |
| Req 10.5.1 | Retain audit history at least 12 months (>= 3 months immediately available). | `atoms/cloudwatch-log-group` — retention >= 365 days | `config.retention_in_days = 365` | `config.allow_no_retention = true` (permits `0` = never expire) |
| Req 10.2 / 10.3 | Capture access to stored data for audit trails. | `atoms/s3-bucket` — server access logging to a target bucket | `config.logging_target_bucket` (`null` = no access logging), `config.logging_target_prefix = "s3-access-logs/"` | n/a — opt-in by setting `config.logging_target_bucket`; no escape hatch |

> Field names above are verified against each atom's `variables.tf`
> (`kms-key`, `s3-bucket`, `security-group`, `vpc`, `subnet`, `iam-role`,
> `cloudwatch-log-group`) as of this revision. All inputs are fields on the
> single `config` object; all outputs are fields on the single `manifest`
> object.

## Exceptions process

A relaxed control is permitted only with a **documented PCI exception**.

1. **File the exception.** Email `security@emag.ro` with: the resource/module,
   the control being relaxed, business justification, scope (is the CDE
   affected?), compensating controls, and an expiry/review date.
2. **Flip the escape hatch** (`allow_* = true`) inside the `config = { ... }`
   block of the Terraform call, citing the exception ID in a code comment.
3. **Keep scans green and documented.** Add a matching `checkov:skip` comment on
   the resource that cites the same exception ID, e.g.:

   ```hcl
   module "data_bucket" {
     source = "../../atoms/s3-bucket"
     config = {
       bucket = "cde-evidence-store"
       # checkov:skip=CKV_AWS_XXX: PCI exception PCI-EX-2026-014, approved security@emag.ro, review 2026-12-01
       allow_unencrypted = true
     }
   }
   ```

### Auditing relaxed controls repo-wide

```bash
# Every place a control was deliberately weakened:
grep -rn "allow_[a-z_]* *= *true" --include='*.tf' .

# Every documented skip and the exception it cites:
grep -rn 'checkov:skip' --include='*.tf' .
```

The `allow_*` escape hatches now live inside each call's `config = { ... }`
block (one `config` object per module), so the hits above appear within those
blocks rather than as loose top-level arguments. Every `allow_* = true` hit
should have a corresponding `checkov:skip` citing an exception ID. A hit
without one is an undocumented deviation and a finding.

## Disclaimer — necessary, not sufficient

These module defaults are **necessary baseline controls, not a PCI DSS
attestation.** Full compliance also depends on factors outside this library:

- **Org-level controls** — SCPs, IAM account policy, MFA, IdP, key management
  governance, change management.
- **Scoping** — what is actually in the Cardholder Data Environment, network
  segmentation validation, and data flow / data retention decisions.
- **Runtime configuration** — how callers wire the atoms together, what data
  they store, application-layer handling of account data, and operational
  monitoring/alerting on the logs these modules produce.
- **Assessment** — a QSA must assess the environment; this matrix is evidence
  toward, not a substitute for, that assessment.

Requirement numbers reflect the PCI DSS v4.0 structure at the requirement-family
level. Where an exact sub-requirement is uncertain it is described generally;
validate against the current official standard before using this matrix as
audit evidence.
