# PCI DSS v4.0 — Practical Guide for the PAWS Terraform Library

> Internal / confidential — eMAG Group (RO, BG, HU, PL).
> Subject to PCI DSS v4.0, NIS2, DORA, GDPR.
> Security exceptions & questions: **security@emag.ro**.

---

## 1. Purpose & how to use this guide

This guide is for engineers raising AWS infrastructure **into, or adjacent to, the
Cardholder Data Environment (CDE)** using the PAWS Terraform module library, and
for the security reviewers who sign off on those changes.

It is the **actionable, per-module companion** to two existing documents:

- [`CONVENTIONS.md`](../CONVENTIONS.md) — the contract every module obeys.
- [`docs/pci-dss-mapping.md`](./pci-dss-mapping.md) — the master **control matrix**
  (which `config` field enforces which requirement).

Where the matrix tells you *what control maps to what requirement*, this guide
tells you *what you get for free, what you still have to do, and what you must
never do* in CDE scope — component by component, blueprint by blueprint.

**The library model in one paragraph.** Every module is `config`-in / `manifest`-out:
one `config` object input, one `manifest` object output. Every default is the
PCI-compliant value, so `config = {}` (where allowed) yields a compliant resource.
Weakening a control requires flipping a grep-able `allow_*` escape hatch that also
trips a `lifecycle` precondition whose error message points at security@emag.ro.
Global tags come from the AWS provider `default_tags`, set once at the root.
Layers stack bottom-up: **atoms** (1 resource) → **components** (1 capability) →
**blueprints** (1 environment).

> How to read each component block: **PCI hooks** (requirements touched) ·
> **Secure by default** (free) · **You must still** (your job) · **Do NOT in CDE**
> (the real escape hatches to keep off) · **Evidence for the QSA** (what to capture).

---

## 2. PCI DSS essentials for this library

### CDE & scope

The **CDE** is every system component that stores, processes, or transmits
cardholder data (CHD/account data), plus anything connected to or that could
impact the security of those systems. PCI's golden rule: **shrink the CDE.**
The smaller the in-scope footprint, the less to assess and the lower the risk.

### Segmentation shrinks scope

Network segmentation is how you keep systems *out* of scope. This library gives
you the primitives — private subnets by default (`secure-network`), no-implicit-allow
security groups and NACLs, private-only databases/caches, VPC endpoints to keep
traffic off the internet. **Segmentation must be designed and then tested**; a
module default does not prove an out-of-scope system is truly isolated.

### AWS shared responsibility

PCI compliance on AWS is split:

- **AWS** is responsible for the security *of* the cloud (physical data centres,
  hypervisor, managed-service substrate) — see AWS's PCI DSS AOC/Responsibility
  Matrix. This covers most of **Req 9 (physical)**.
- **You** are responsible for security *in* the cloud — how you configure
  services, who has access, what you log, how you segment. This library codifies
  the *technical* slice of that responsibility.

### NECESSARY BUT NOT SUFFICIENT

> **These module defaults are necessary baseline technical controls. They are not,
> on their own, PCI DSS compliance and they are not an attestation.**

Full compliance additionally requires things this library cannot produce:
organizational policy (Req 12), correct scoping decisions, **segmentation
penetration testing** (Req 11.4.5), broader **penetration testing** and **ASV
scans** (Req 11.3/11.4), a **QSA assessment / ROC or SAQ**, key-management
governance, change management, incident response, and the operational process of
actually *monitoring* the logs and alarms these modules emit.

### The escape hatches are the audit surface

Every `allow_*` field is a deliberately weakened control. **In CDE scope they
generally must NOT be used.** Any use requires:

1. A documented, risk-assessed **PCI exception** filed with **security@emag.ro**
   (resource, control relaxed, justification, scope, compensating controls,
   expiry/review date), and
2. A matching **`checkov:skip`** comment on the resource citing the exception ID,
   so scans stay green *and* documented.

Audit the whole repo for deviations:

```bash
# Every place a control was deliberately weakened:
grep -rn "allow_[a-z_]* *= *true" --include='*.tf' .
# Every documented skip + the exception it cites:
grep -rn 'checkov:skip' --include='*.tf' .
```

An `allow_* = true` without a matching `checkov:skip` and a filed exception is an
**undocumented deviation and a finding.**

---

## 3. Requirement-by-requirement: what the library gives you

PCI DSS v4.0 requirements 1–12. "Helps" cites **real** module names; "Your
responsibility" is honest about the gaps.

| Req | Intent (1 line) | Library helps (real modules) | Remains your responsibility |
|---|---|---|---|
| **1** Network security controls / segmentation | Restrict in/outbound to only what's needed; segment the CDE. | `secure-network` (private subnets, flow logs), `network-acl`, `vpc-endpoints`, `security-group` atom, DB/cache components' `allowed_security_group_ids`/`allowed_cidrs`, `alb` (internal by default) | Design & **test** segmentation; choose real CDE-only CIDRs; review rules; ruleset change management. |
| **2** Secure configurations / no defaults | Harden config; no vendor defaults. | Secure-by-default config across all modules; `account-baseline` password policy; immutable ECR tags | OS/app/container hardening (CIS benchmarks); inventory; remove unused services. |
| **3** Protect stored account data | Render stored data unreadable; manage keys. | KMS-backed encryption on `private-encrypted-bucket`, `rds-*`, `dynamodb`, `elasticache`, `kafka`, `mq`, `secrets-manager`, `ssm-parameters`, `sns`, `sqs`, log groups; `macie` (CHD discovery) | **Do not store CHD unless required**; data-retention/purge rules; PAN masking/truncation; key-management governance & ownership. |
| **4** Protect data in transit | Strong crypto over open networks. | `alb` (TLS-only, TLS1.2/1.3 policy), `cloudfront` (TLS1.2_2021 min), `acm`, `rds-proxy` (`require_tls`), `elasticache` (transit encryption), `kafka`/`mq` (TLS in transit) | End-to-end TLS to the app; cert lifecycle; cipher policy review; no TLS termination outside the CDE boundary you intend. |
| **5** Anti-malware | Protect against malicious software. | `inspector` / `cspm` Inspector (vuln scanning of ECR/EC2/Lambda) is adjacent, not AV | Endpoint anti-malware where applicable; mostly out of IaC scope. |
| **6** Secure systems & software | Patch; secure SDLC; vuln management; WAF. | `ecr` (scan-on-push, immutable tags), `inspector`/`cspm` (continuous vuln scan), `waf` (Req 6.6 public-app protection) | SDLC, code review, patch SLAs, triage of findings, WAF rule tuning. |
| **7** Least privilege / need-to-know | Grant only needed access; deny by default. | `iam-role`/`iam-policy` atoms (no admin/wildcard default), `iam-ci-oidc`, `iam-group`, `iam-user` (no static keys), `iam-access-analyzer`, permissions boundaries | Author least-privilege policies; periodic access review; role/entitlement ownership. |
| **8** Identify & authenticate | Unique IDs; strong auth; MFA. | `iam-ci-oidc` (keyless federation, no static keys), `iam-user` (identity only, no access keys), `account-baseline` (password length/age/reuse), secrets sourced from a vault | MFA enforcement (IdP/SCP), human-identity governance, joiner/mover/leaver, session policy at org level. |
| **9** Physical access | Restrict physical access to CHD. | **Mostly AWS's responsibility** (shared model); not an IaC concern. `backup` aids media/retention durability. | Office/media handling; rely on AWS AOC for data-centre controls. |
| **10** Log & monitor all access | Record and alert on access to CDE & resources. | `cloudtrail`, `audit-logging` (365-day encrypted log sink), `cloudwatch-alarms` (security-event alarms), `findings-notification`, `secure-network` flow logs, `route53` query logging, per-component log groups | Wire alarms to a **monitored** SNS; log review process; time-sync; 12-month retention enforcement & access to it. |
| **11** Test security of systems | Vuln scans, pen tests, **segmentation tests**, IDS. | `cspm` (GuardDuty IDS-like, Config, Security Hub), `inspector` (continuous CVE scan) | **ASV scans, internal/external pen tests, segmentation pen test** — all out of IaC scope; schedule & evidence them. |
| **12** Org policy & programs | Information-security policy & process. | `backup` retention helps a data-availability program; otherwise minimal | Security policy, risk assessment, TPSP management, IR plan, training — **organizational, not IaC.** |

> **Honest gaps:** Req 5, 9, and 12 are largely outside what Terraform modules can
> deliver. Req 11's testing obligations (pen test, ASV, segmentation test) are
> process, not config. The library helps you *produce evidence* for Req 10/11,
> not *pass* them.

---

## 4. Per-component PCI checklist

Total components covered below: **40** (every directory under `aws/components/`).
Field names and escape hatches are taken verbatim from each component's
`variables.tf`. Where an escape hatch exists only on the underlying *atom* (not
surfaced by the component) that is noted.

### Network

#### `secure-network`
- **PCI hooks:** Req 1 (segmentation), Req 10 (flow logs).
- **Secure by default:** subnets are **private** (`public = false`); VPC **flow logs
  on** (`enable_flow_logs = true`, `flow_log_retention_in_days = 365`); NAT egress
  is `single` by default; can consume a central BYO flow-log sink
  (`byo_flow_log_destination_arn` + `byo_flow_log_role_arn`).
- **You must still:** size CIDRs for real CDE/non-CDE segmentation; only mark a
  subnet `public = true` when truly needed (and document it); choose
  `nat_gateway_mode = per_az` for prod HA; point flow logs at your central sink.
- **Do NOT in CDE:** `allow_flow_logs_disabled = true`.
- **Evidence:** `terraform plan`/manifest showing subnet map, flow-log config &
  destination, route tables.

#### `vpc-endpoints`
- **PCI hooks:** Req 1 (keep traffic off the internet).
- **Secure by default:** curated Gateway (`s3`, `dynamodb`) + Interface endpoints
  (ecr, logs, secretsmanager, kms, ssm, sts, monitoring…); Interface ENIs reachable
  only from the VPC CIDR when `allowed_cidrs` is left empty.
- **You must still:** confirm the service list matches what the CDE workload uses;
  if you set `allowed_cidrs`, scope to CDE CIDRs only; place ENIs in private subnets.
- **Do NOT in CDE:** no `allow_*` hatch here — do not widen `allowed_cidrs` to the
  internet or other segments.
- **Evidence:** endpoint list + policy, the `allowed_cidrs` value.

#### `network-acl`
- **PCI hooks:** Req 1 (subnet-level segmentation).
- **Secure by default:** every rule needs an explicit `allow`/`deny` action (no
  implicit allow); admin-port-to-internet and any-internet ingress are rejected by
  preconditions.
- **You must still:** number rules deliberately; associate the right `subnet_ids`;
  keep CDE NACLs deny-by-default with explicit narrow allows.
- **Do NOT in CDE:** `allow_public_ingress = true`, `allow_public_admin_ports = true`.
- **Evidence:** rule list, subnet associations.

### Data

#### `private-encrypted-bucket`
- **PCI hooks:** Req 3 (encryption at rest), Req 10 (versioning + access logging).
- **Secure by default:** SSE-KMS (creates a dedicated CMK if `kms_key_arn` null);
  versioning on; access logging on (auto companion `${bucket}-logs` bucket);
  public access blocked.
- **You must still:** own CMK rotation if BYOK; set `lifecycle_rules` to your
  retention policy; keep `additional_policy_statements` least-privilege.
- **Do NOT in CDE:** the relaxers live on the `s3-bucket` *atom* —
  `allow_unencrypted`, `allow_unversioned`, `allow_public_access`. Never flip them
  for a CHD bucket.
- **Evidence:** manifest (bucket + KMS ARN), encryption/versioning/PAB config,
  access-log target.

#### `rds-aurora` · `rds-aurora-serverless` · `rds-instance`
- **PCI hooks:** Req 1 (private DB SG), Req 3 (encryption), Req 10/resilience (backups).
- **Secure by default:** storage encrypted (dedicated CMK if none supplied);
  deletion protection on; **DB SG has no ingress unless** you list
  `allowed_security_group_ids`/`allowed_cidrs`; `backup_retention_period = 14`
  (7–35); requires ≥2 subnets across AZs.
- **You must still:** restrict ingress to the **app SG only** (prefer SG refs over
  CIDRs); enable deletion protection in prod (it is the default — keep it); supply
  `monitoring_role_arn` if enabling enhanced monitoring; own BYO CMK rotation.
- **Do NOT in CDE:** `allow_unencrypted = true`, `allow_deletion = true`, and on
  `rds-instance` also `allow_public = true`.
- **Evidence:** plan/manifest showing `storage_encrypted`, KMS ARN, DB SG ingress,
  `deletion_protection`, retention, subnet group AZs.

#### `rds-proxy`
- **PCI hooks:** Req 1 (private), Req 4 (TLS), Req 8 (creds from Secrets Manager).
- **Secure by default:** `require_tls = true`; proxy SG ingress only from listed
  app SGs/CIDRs; DB creds come from `secret_arns` (Secrets Manager).
- **You must still:** scope ingress to CDE app SGs; keep secrets in the vault with
  rotation; target exactly one DB instance or cluster.
- **Do NOT in CDE:** `allow_plaintext = true` (disables `require_tls`).
- **Evidence:** `require_tls` setting, SG ingress, secret ARNs (not values).

#### `dynamodb`
- **PCI hooks:** Req 3 (encryption), resilience (PITR).
- **Secure by default:** CMK encryption (dedicated key if `kms_key_arn` null);
  point-in-time recovery on; deletion protection on; `PAY_PER_REQUEST`.
- **You must still:** own BYO CMK rotation; set TTL only where data-retention rules
  allow; review GSIs for over-exposure of attributes.
- **Do NOT in CDE:** relaxers are on the `dynamodb-table` *atom* —
  `allow_aws_owned_key`, `allow_no_pitr`, `allow_deletion`.
- **Evidence:** SSE type + KMS ARN, PITR status, deletion protection.

#### `elasticache`
- **PCI hooks:** Req 1 (private), Req 3 (at-rest), Req 4 (in-transit), Req 8 (AUTH).
- **Secure by default:** at-rest + in-transit encryption; CMK; Multi-AZ
  (`num_cache_clusters > 1` enforced); cache SG ingress only from listed app
  SGs/CIDRs; `config` is `sensitive` (carries `auth_token`).
- **You must still:** supply `auth_token` **from Secrets Manager, never a literal**;
  scope ingress to CDE app SGs; own BYO CMK rotation.
- **Do NOT in CDE:** relaxers are on the `elasticache-replication-group` *atom* —
  `allow_unencrypted_at_rest`, `allow_plaintext_in_transit`.
- **Evidence:** at-rest/transit encryption flags, KMS ARN, SG ingress (redact token).

### Compute

#### `ecs-cluster`
- **PCI hooks:** Req 3 (exec-log encryption), Req 10 (logging).
- **Secure by default:** Container Insights on; execute-command logging to a
  CMK-encrypted log group; `log_retention_days = 365`; Fargate capacity providers.
- **You must still:** supply/own the CMK if BYOK; set retention to your policy.
- **Do NOT in CDE:** relaxer on the `ecs-cluster` *atom* —
  `allow_container_insights_disabled = true`.
- **Evidence:** cluster setting, log group + KMS, retention.

#### `ecs-service`
- **PCI hooks:** Req 1 (private tasks), Req 3 (log encryption), Req 10 (logs).
- **Secure by default:** `assign_public_ip = false`; CMK-encrypted app log group
  (`kms_key_arn` required unless escaped); `log_retention_days = 365`; autoscaling
  on; `desired_count = 2`; ingress rules require a `description`.
- **You must still:** scope `ingress_rules` to the ALB SG / CDE CIDRs; least-privilege
  `task_role_arn`/`execution_role_arn`; keep tasks in private subnets.
- **Do NOT in CDE:** `allow_public_ip = true`, `allow_unencrypted_logs = true`.
- **Evidence:** network config (`assign_public_ip`), SG ingress, log group + KMS.

#### `lambda-function`
- **PCI hooks:** Req 1 (optional VPC + egress), Req 3 (env-var/log encryption), Req 10 (X-Ray, logs).
- **Secure by default:** env vars + logs encrypted with a CMK; X-Ray active tracing
  on; `log_retention_days = 365`; `arm64`; documented egress rules when VPC-attached.
- **You must still:** never put secrets in `environment_variables` (use Secrets
  Manager/SSM); scope `egress_rules`; attach to a VPC for CDE workloads; own BYO CMK.
- **Do NOT in CDE:** relaxer on the `lambda-function` *atom* —
  `allow_unencrypted_env = true`.
- **Evidence:** KMS on env vars + log group, X-Ray flag, VPC/egress config.

### Edge

#### `alb`
- **PCI hooks:** Req 1 (exposure), Req 4 (TLS), Req 10 (access logs).
- **Secure by default:** `internal = true` (not internet-facing); listeners default
  to HTTPS with `ELBSecurityPolicy-TLS13-1-2-2021-06`; access logs to S3 on;
  ingress is **not** open to the internet unless escaped.
- **You must still:** scope `ingress_cidrs` to expected sources; provide a real
  `certificate_arn`; if internet-facing, front with WAF; ship logs to a retained bucket.
- **Do NOT in CDE:** `allow_internet_facing = true`, per-listener
  `allow_insecure_http = true`, `allow_public_ingress = true`.
- **Evidence:** `internal` flag, listener protocol + `ssl_policy`, ingress CIDRs,
  access-log bucket.

#### `cloudfront`
- **PCI hooks:** Req 1/7 (S3 via OAC, no public bucket), Req 4 (TLS), Req 6 (WAF), Req 10 (logs).
- **Secure by default:** viewer TLS min `TLSv1.2_2021`; S3 origins fronted by OAC;
  access logging on; can attach a `web_acl_arn` (WAF).
- **You must still:** attach WAF on public entrypoints (Req 6.6); ACM cert must be
  in **us-east-1** and is required when `aliases` set; restrict origin access.
- **Do NOT in CDE:** relaxers are on the `cloudfront-distribution` *atom* —
  `allow_weak_tls = true`, `allow_insecure_viewer = true` (the component does not
  surface them).
- **Evidence:** min TLS version, OAC config, attached WAF ARN, log bucket.

#### `waf`
- **PCI hooks:** Req 6.6 (protect public apps), Req 10 (request logging).
- **Secure by default:** managed rule groups; CMK-encrypted log group;
  `log_retention_days = 365`; scope `REGIONAL` (ALB/APIGW) or `CLOUDFRONT`.
- **You must still:** tune rule groups & `rate_limit` for the app; associate the
  right resources (`associate_resource_arns`, REGIONAL only); review blocked/counted.
- **Do NOT in CDE:** relaxer on the `wafv2-web-acl` *atom* — `allow_logging_disabled = true`.
- **Evidence:** rule groups, associations, log group + KMS + retention.

#### `acm`
- **PCI hooks:** Req 4 (TLS certificates).
- **Secure by default:** DNS-validated public cert tied to a Route53 zone.
- **You must still:** scope `domain_name`/`subject_alternative_names` to **real**
  domains you control; ensure auto-renewal validation records persist.
- **Do NOT in CDE:** no `allow_*` hatch.
- **Evidence:** cert ARN, domain/SANs, validation method.

#### `dns-record` · `route53`
- **PCI hooks:** Req 10 (query logging — `route53` zones).
- **Secure by default:** `route53` public zones get CMK-encrypted query logging
  with `log_retention_days = 365`; `dns-record` enforces unique (name,type) and
  exactly one of value/alias.
- **You must still:** point records at intended targets; private zones can't query-log
  (expected); own BYO CMK.
- **Do NOT in CDE:** relaxers are on atoms — `route53-record` `allow_overwrite`,
  `route53-zone` `allow_query_logging_disabled`.
- **Evidence:** query-logging config + retention (zones); record set (records).

### Messaging

#### `sns`
- **PCI hooks:** Req 3 (encryption), Req 4 (topic policy).
- **Secure by default:** CMK SSE (dedicated key if `kms_key_arn` null);
  least-privilege topic policy.
- **You must still:** keep `additional_policy_statements` scoped; validate subscription endpoints.
- **Do NOT in CDE:** relaxer on the `sns-topic` *atom* — `allow_unencrypted = true`.
- **Evidence:** KMS key, topic policy.

#### `sqs`
- **PCI hooks:** Req 3 (encryption), Req 4 (queue policy), resilience (DLQ).
- **Secure by default:** CMK SSE; DLQ on (`enable_dlq`, `max_receive_count = 5`);
  retention 4 days.
- **You must still:** tune retention to data rules; scope queue policy.
- **Do NOT in CDE:** relaxer on the `sqs-queue` *atom* — `allow_unencrypted = true`.
- **Evidence:** KMS key, DLQ config, queue policy.

#### `kafka` (MSK)
- **PCI hooks:** Req 1 (private SG), Req 3 (at-rest), Req 4 (in-transit), Req 10 (logging).
- **Secure by default:** CMK at rest; TLS client-broker + in-cluster encryption;
  broker SG ingress only from listed SGs/CIDRs; broker logs retained 365 days; ≥3 brokers.
- **You must still:** scope ingress to CDE; own BYO CMK; manage client auth.
- **Do NOT in CDE:** relaxers on the `msk-cluster` *atom* — `allow_unencrypted_at_rest`,
  `allow_plaintext_in_transit`, `allow_logging_disabled`.
- **Evidence:** encryption-in-transit/at-rest config, SG ingress, logging config.

#### `mq`
- **PCI hooks:** Req 1 (private), Req 3 (at-rest), Req 8 (broker user creds).
- **Secure by default:** CMK at rest; broker SG ingress only from listed SGs/CIDRs;
  Multi-AZ default; `config` is `sensitive` (carries user passwords).
- **You must still:** source `users[].password` from a vault, never hardcode; scope ingress.
- **Do NOT in CDE:** relaxers on the `mq-broker` *atom* — `allow_public = true`,
  `allow_aws_owned_key = true`.
- **Evidence:** at-rest KMS, deployment mode, SG ingress (redact passwords).

### Secrets / Config

#### `secrets-manager`
- **PCI hooks:** Req 3 (encryption), Req 8 (credential handling).
- **Secure by default:** every secret encrypted with a CMK; `recovery_window_in_days = 30`;
  optional rotation (`rotation_lambda_arn`, `rotation_days = 30`).
- **You must still:** supply secret **values out of band**, never in source; wire
  rotation lambdas for credentials; own BYO CMK.
- **Do NOT in CDE:** relaxers on the `secretsmanager-secret` *atom* —
  `allow_aws_managed_key = true`, `allow_immediate_deletion = true`.
- **Evidence:** KMS key, recovery window, rotation config (never values).

#### `ssm-parameters`
- **PCI hooks:** Req 3 (encryption), Req 8 (credential handling).
- **Secure by default:** SecureString parameters CMK-encrypted; `config` marked
  `sensitive`.
- **You must still:** never hardcode real secrets in `parameters[].value`; prefer
  Secrets Manager for rotating credentials; own BYO CMK.
- **Do NOT in CDE:** relaxer on the `ssm-parameter` *atom* — `allow_plaintext = true`.
- **Evidence:** parameter type + KMS (never values).

### Identity

#### `iam-ci-oidc`
- **PCI hooks:** Req 7 (least privilege), Req 8 (no static keys / keyless federation).
- **Secure by default:** keyless GitHub-OIDC role; `subjects` required and scoped;
  wildcard-only subject rejected; `max_session_duration = 3600`.
- **You must still:** scope `subjects` to specific repos/branches/environments;
  keep `managed_policy_arns`/`inline_policies` least-privilege; set a
  `permissions_boundary`.
- **Do NOT in CDE:** `allow_wildcard_subject = true`.
- **Evidence:** trust policy (`sub` conditions), attached policies, session duration.

#### `iam-user`
- **PCI hooks:** Req 7, Req 8.
- **Secure by default:** creates **identity only — no static access keys, no login
  profile**; optional `permissions_boundary`.
- **You must still:** prefer roles/OIDC over users; if keys are unavoidable, manage
  & rotate them outside this module with a filed justification.
- **Do NOT in CDE:** no `allow_*` hatch.
- **Evidence:** user identity, permissions boundary, absence of keys.

#### `iam-group`
- **PCI hooks:** Req 7 (least privilege by membership).
- **Secure by default:** group with explicit `managed_policy_arns` and `users`
  (ARNs validated).
- **You must still:** attach least-privilege policies; review membership each quarter.
- **Do NOT in CDE:** no `allow_*` hatch (do not attach admin policies).
- **Evidence:** group policies, membership list.

#### `account-baseline`
- **PCI hooks:** Req 8.3.6/8.3.7/8.3.9 (password policy).
- **Secure by default:** `password_minimum_length = 14`, `password_max_age = 90`,
  `password_reuse_prevention = 4`, `require_symbols = true`; **no escape hatch** —
  preconditions hard-enforce the PCI floors (≥12, ≥4 reuse, 1–365 age).
- **You must still:** this covers IAM password policy only; MFA and IdP/SSO auth
  are org-level (Req 8.4/8.5).
- **Do NOT in CDE:** n/a — component refuses sub-PCI values; weaken on the atom only
  with an exception.
- **Evidence:** account password-policy settings.

### Audit / Posture

#### `audit-logging`
- **PCI hooks:** Req 3 (encryption), Req 10 (central retained log sink).
- **Secure by default:** CMK-encrypted central log group; `retention_in_days = 365`;
  optional flow-log delivery role.
- **You must still:** route component/flow logs here; ensure 12-month retention &
  access matches policy; own BYO CMK.
- **Do NOT in CDE:** `allow_no_retention = true` (passed to the log-group atom).
- **Evidence:** log group, KMS key, retention, flow-log role.

#### `cloudtrail`
- **PCI hooks:** Req 10 (the audit backbone).
- **Secure by default:** CMK-encrypted trail; CloudWatch retention 365 days; log-file
  validation on (atom default); multi-region capable.
- **You must still:** enable as an org trail where appropriate; protect the S3 store
  (object lock); review for gaps.
- **Do NOT in CDE:** relaxers on the `cloudtrail` *atom* — `allow_unencrypted = true`,
  `allow_log_validation_disabled = true`.
- **Evidence:** trail config (multi-region, validation, KMS), retention.

#### `cloudwatch-alarms`
- **PCI hooks:** Req 10.6 (alert on security events).
- **Secure by default:** full baseline alarm set (unauthorized API calls, console
  sign-in w/o MFA, root usage, IAM/CloudTrail/CMK/SG/NACL/route/VPC changes…);
  encrypted SNS topic if `sns_topic_arn` not supplied.
- **You must still:** **wire the SNS to a monitored channel** (PagerDuty/email/SIEM)
  — alarms are worthless unanswered; point at the real CloudTrail log group.
- **Do NOT in CDE:** no `allow_*` hatch; do not prune `enabled_alarms` below your
  required set.
- **Evidence:** the alarm list, SNS subscription proof, escalation runbook.

#### `findings-notification`
- **PCI hooks:** Req 10 (route Security Hub/Inspector/GuardDuty findings to SNS).
- **Secure by default:** CMK-encrypted SNS; EventBridge rule per `source` (`all` default).
- **You must still:** subscribe a monitored endpoint; triage findings on an SLA.
- **Do NOT in CDE:** no `allow_*` hatch.
- **Evidence:** event rule, SNS + KMS, subscription.

#### `cspm`
- **PCI hooks:** Req 6/10/11 (posture: Security Hub + Config + GuardDuty + Inspector).
- **Secure by default:** all four enabled (`enable_* = true`); Inspector scans
  `ECR`, `EC2`, `LAMBDA`.
- **You must still:** act on Config non-compliance, GuardDuty/Inspector findings;
  keep all enabled in CDE accounts.
- **Do NOT in CDE:** no `allow_*` hatch; do not flip an `enable_*` off in CDE scope
  without an exception.
- **Evidence:** enabled services, Inspector resource types, Config recorder status.

#### `inspector`
- **PCI hooks:** Req 6 & 11 (continuous vulnerability scanning).
- **Secure by default:** scans `ECR`/`EC2`/`LAMBDA`; optional CMK-encrypted findings SNS.
- **You must still:** triage CVEs on a patch SLA; subscribe the notification topic.
- **Do NOT in CDE:** no `allow_*` hatch.
- **Evidence:** enabled resource types, findings pipeline.

#### `iam-access-analyzer`
- **PCI hooks:** Req 7 (detect external/over-broad access).
- **Secure by default:** `ACCOUNT` analyzer; supports unused-access analyzers.
- **You must still:** review & remediate analyzer findings; consider
  `ORGANIZATION`/unused-access types.
- **Do NOT in CDE:** no `allow_*` hatch.
- **Evidence:** analyzer type, findings review.

#### `macie`
- **PCI hooks:** Req 3 / Req A (discover stored cardholder/sensitive data).
- **Secure by default:** **ENABLED** with `{}`; `FIFTEEN_MINUTES` publishing.
- **You must still:** configure classification jobs against CHD-bearing buckets;
  use findings to confirm CHD location & scope.
- **Do NOT in CDE:** no `allow_*` hatch (do not set `status = PAUSED` in CDE scope).
- **Evidence:** Macie status, classification job results.

#### `ecr`
- **PCI hooks:** Req 3 (encryption), Req 6 & 11 (scan-on-push, Inspector), image integrity.
- **Secure by default:** CMK encryption; **scan-on-push** on; **immutable tags**;
  lifecycle policy (`untagged_expiry_days = 14`); account Inspector ECR scanning on.
- **You must still:** gate deploys on scan results; keep `additional_repository_policy`
  least-privilege; own BYO CMK.
- **Do NOT in CDE:** relaxers on the `ecr-repository` *atom* —
  `allow_scan_on_push_disabled = true`, `allow_mutable_tags = true`.
- **Evidence:** scan-on-push setting, tag immutability, KMS, lifecycle policy.

### Resilience

#### `backup`
- **PCI hooks:** Req 10.5.1 (retention) / availability; supports Req 9/12 data programs.
- **Secure by default:** CMK-encrypted vault; daily schedule; `delete_after_days = 35`;
  selection by tag (`Backup = "true"`) and/or ARNs; optional **Vault Lock** (WORM).
- **You must still:** set retention to your data-retention policy; enable
  `enable_vault_lock` (consider `compliance` mode) for critical CDE data; verify
  restores; tag in-scope resources.
- **Do NOT in CDE:** relaxer on the `backup-vault` *atom* — `allow_unencrypted = true`.
- **Evidence:** vault KMS, schedule, retention, vault-lock mode, selection.

---

## 5. Per-blueprint PCI checklist

### `fargate-web-service`

End-to-end public web service: optional `secure-network` → `alb` (+ optional `waf`)
→ `ecs-service` on `ecs-cluster`, with optional Aurora (`rds-aurora` /
`rds-aurora-serverless`), `elasticache`, `secrets-manager`, `ecr`, `acm`, and a
`dns-record`. Central `audit-logging` is always composed.

- **CDE boundary:** the data tier (Aurora/cache/secrets) and the app tasks are the
  CDE; the **public ALB / optional CloudFront edge is the highest-risk surface.**
  Keep tasks and DB in **private** subnets; DB/cache SGs admit only the app SG.
- **Segmentation:** with `create_network = true` you get private-by-default subnets;
  with BYO network you must supply ≥2 public + ≥2 private subnets and ensure they're
  correctly segmented from non-CDE.
- **TLS:** the ALB **always terminates TLS at the edge** — there is *no* plain-HTTP
  escape hatch at blueprint level; a cert is mandatory (`domain_name` + `hosted_zone_id`
  via ACM, or BYO `certificate_arn`). Ensure TLS continues to the app where required.
- **Logging → retention:** ALB access logs, ECS app logs (CMK, 365d), and central
  audit logging are wired; confirm they reach a 12-month-retained, access-controlled sink.
- **Monitoring/alerting:** this blueprint does **not** itself compose
  `cloudwatch-alarms` — pair it with `secure-landing-zone` (or add alarms) so security
  events page someone.
- **Backup:** enable `backup` for the Aurora/data tier; turn on deletion protection
  (default) and vault lock for prod.
- **Optional tiers that ADD scope:** `enable_database`, `enable_cache`,
  `enable_secrets` each pull a CHD-capable store into the CDE — only enable what you
  need (scope minimization).
- **Public entrypoint risk:** keep `enable_waf = true`; never set the ALB's
  `allow_internet_facing`/`allow_public_ingress` without an exception; restrict
  source CIDRs.

### `secure-landing-zone`

Account baseline: `account-baseline` (password policy) + `audit-logging` +
`cloudtrail` + `cspm` (Security Hub/Config/GuardDuty/Inspector) +
`findings-notification`, with an **optional** baseline `secure-network`.

- **What it establishes:** the Req 8 password floor, the Req 10 logging backbone
  (encrypted trail + central log sink + retention), and the Req 6/10/11 posture
  stack — the things every CDE account needs *before* workloads land.
- **CDE boundary:** this is account-wide guardrails, not a workload; it makes the
  account *fit to host* a CDE. Network is OFF by default (`enable_network = false`).
- **Shared CMK:** one `kms_key_arn` can encrypt the log group, trail store, Config
  bucket, and findings topic — or each owns its own.
- **Monitoring/alerting:** `findings-notification` routes findings to SNS — subscribe
  a monitored channel. Add/compose `cloudwatch-alarms` against the trail's log group
  for Req 10.6 event alarms.
- **Org-level note:** organization trail / org-wide Config and SCPs are partly here
  (`*_is_organization_trail`) but **multi-account org governance is out of scope** —
  see §7.
- **Public entrypoint risk:** none directly (no public edge); risk arrives with the
  workloads you deploy on top (e.g. `fargate-web-service`).

---

## 6. "Before you go live in the CDE" checklist

Tick every box. Anything unchecked is a finding or an exception.

- [ ] **No escape hatches flipped** — `grep -rn "allow_[a-z_]* *= *true" --include='*.tf' .`
      returns nothing in CDE scope (or each hit has a filed exception **and** a
      matching `checkov:skip`).
- [ ] **`default_tags` set at the provider/root**, including an **`Environment`** and a
      **data-classification** tag (e.g. `DataClassification`/`Compliance`).
- [ ] **CloudTrail on** (multi-region, log-file validation, CMK) via `cloudtrail` /
      `secure-landing-zone`.
- [ ] **AWS Config + GuardDuty + Inspector on** via `cspm` (`enable_* = true`).
- [ ] **`cloudwatch-alarms` deployed and wired to a *monitored* SNS** (PagerDuty/SIEM),
      with an escalation runbook (Req 10.6).
- [ ] **VPC flow logs on** (`secure-network` default) delivering to the retained sink.
- [ ] **KMS key rotation** verified for every CMK (BYO keys: rotation is *your* job).
- [ ] **Log retention ≥ 365 days** on every log group / trail (default — confirm not relaxed).
- [ ] **Backups + Vault Lock** configured for critical CHD data (`backup`,
      `enable_vault_lock`), and a **restore test** performed.
- [ ] **WAF on every public entrypoint** (`waf` on ALB / CloudFront).
- [ ] **Least-privilege IAM reviewed** — no admin/wildcard policies, OIDC subjects
      scoped, permissions boundaries set; `iam-access-analyzer` findings clean.
- [ ] **Segmentation validated** — CDE SGs/NACLs admit only intended sources; DB/cache
      ingress is app-SG-only; no public IPs on CDE compute.
- [ ] **TLS everywhere** — ALB/CloudFront TLS1.2+; `rds-proxy require_tls`; cache/Kafka/MQ
      in-transit encryption on.
- [ ] **Secrets in a vault** — no literals in `environment_variables`, `parameters`,
      `auth_token`, or broker passwords; rotation configured.
- [ ] **Macie classification** confirms where CHD actually lives (scope check).
- [ ] **Quarterly access review** scheduled (Req 7/8).
- [ ] **Pen test / ASV scan / segmentation test scheduled** (Req 11) — these are NOT
      delivered by Terraform.

---

## 7. Out of scope / not covered by this library

These are real PCI obligations the modules **cannot** satisfy. Track them elsewhere.

- **Multi-account org governance** — AWS Organizations, SCPs, centralized billing/
  delegated admin. (`secure-landing-zone` touches org *trails* but not org policy.)
- **QSA assessment / ROC / SAQ** — formal attestation by a qualified assessor.
- **Penetration testing, ASV scans, and segmentation penetration testing** (Req 11) —
  process, not config.
- **Physical security (Req 9)** — largely AWS's responsibility under the shared model;
  rely on AWS's PCI AOC.
- **People & policy (Req 12.x)** — security policy, risk assessment, training, incident
  response, TPSP/vendor management.
- **Data-retention business rules** — *how long* CHD may be kept and *when* to purge;
  the modules enforce minimum log/backup retention, not your data-lifecycle policy.
- **Compensating controls** — any control substituted for a relaxed `allow_*` hatch
  must be documented and approved via the exception process (security@emag.ro).

> **Requirement-number caveat:** sub-requirement numbers cited here reflect the
> PCI DSS v4.0 structure at the requirement-family level. The password-policy numbers
> (8.3.6 / 8.3.7 / 8.3.9) and Req 6.6 (public-app protection) are taken directly from
> the module source. Where an exact sub-number was uncertain, the family is cited
> generally (e.g. "Req 11 testing", "Req 10.6 alerting") rather than guessed —
> validate against the current official standard before using this as audit evidence.
