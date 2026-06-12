# Architecture — Design Reference

> Companion to [`CONVENTIONS.md`](../CONVENTIONS.md) (the contract) and
> [`pci-dss-mapping.md`](./pci-dss-mapping.md) (the control matrix).

## The three layers

```
   ┌──────────────────────────────────────────────────────────┐
   │  blueprints/   one deployable environment                 │
   │  e.g. pci-3tier-web-app   ── composes ──▶ components only  │
   └───────────────┬──────────────────────────────────────────┘
                   │  passes IDs / ARNs DOWN by reference
                   ▼
   ┌──────────────────────────────────────────────────────────┐
   │  components/   one capability                              │
   │  e.g. private-encrypted-bucket ── composes ──▶ atoms only  │
   └───────────────┬──────────────────────────────────────────┘
                   │  passes IDs / ARNs DOWN by reference
                   ▼
   ┌──────────────────────────────────────────────────────────┐
   │  atoms/        one logical AWS resource                    │
   │  e.g. kms-key, s3-bucket ── calls aws_* resources directly │
   └──────────────────────────────────────────────────────────┘

   Dependencies flow DOWNWARD only. A lower layer never reaches up.
```

### Hard rules (restated from CONVENTIONS.md §1)

- **Atoms** wrap exactly one logical resource and call `aws_*` resources
  directly. An atom **must not** instantiate another atom or any `*_module`. It
  takes every dependency (KMS ARN, VPC ID, subnet IDs) as an **input**, never
  creating them.
- **Tightly-coupled sub-resource exception:** an atom *may* own sub-resources
  that are meaningless on their own — e.g. the `s3-bucket` atom owns its
  `aws_s3_bucket_versioning`, `_server_side_encryption_configuration`, and
  `_public_access_block`. These are not separate atoms.
- **Components** compose atoms via `module` blocks **only** — no raw `aws_*`
  resources except trivial glue (e.g. a `random_id`).
- **Blueprints** compose components via `module` blocks **only**.
- **Dependencies flow down by reference.** A higher layer creates a resource and
  passes its ID/ARN into the lower layers that need it. Lower layers never
  reach up or create cross-cutting shared resources.

## Worked example — tracing a dependency

A `blueprints/pci-3tier-web-app` deploys a web/app/data three-tier environment.
Watch a single KMS key ARN, created once high up, flow down into multiple atoms.

```
blueprints/pci-3tier-web-app
│
├─ module "kms" → components/audit-logging  (or a dedicated key component)
│      creates ONE customer-managed key  ──▶  output: manifest.arn
│
├─ module "network" → components/secure-network
│      └─ atoms/vpc, atoms/subnet, atoms/security-group
│            vpc enables flow logs → writes to the log group below
│
├─ module "data_bucket" → components/private-encrypted-bucket
│      │   config = { kms_key_arn = module.kms.manifest.arn }   ◀── flows DOWN
│      ├─ atoms/s3-bucket    (config.kms_key_arn ─▶ SSE-KMS encryption, Req 3)
│      └─ atoms/s3-bucket    (the access-log target bucket)
│
└─ module "audit" → components/audit-logging
       │   config = { kms_key_arn = module.kms.manifest.arn }   ◀── flows DOWN
       └─ atoms/cloudwatch-log-group
              (config.kms_key_arn ─▶ encrypted logs, retention 365d, Req 10)
```

Each atom now takes a single `config` object as input and emits a single
`manifest` object as output (CONVENTIONS.md §4/§4a). So the produced ARN is read
as `module.kms.manifest.arn` and consumed as a field on the child's `config`.
In HCL, the key is created and threaded downward like this:

```hcl
# blueprint / component wiring — the key is created once, high up
module "kms" {
  source = "../../atoms/kms-key"
  config = {
    alias               = "cde/data"
    enable_key_rotation = true   # PCI Req 3.6.4 / 3.7 (secure default)
  }
}

module "data_bucket" {
  source = "../../atoms/s3-bucket"
  config = {
    bucket            = "cde-data-store"
    enable_encryption = true                      # secure default
    kms_key_arn       = module.kms.manifest.arn   # ◀── flows DOWN by reference
  }
}

module "audit_logs" {
  source = "../../atoms/cloudwatch-log-group"
  config = {
    name              = "/cde/audit"
    retention_in_days = 365                        # PCI Req 10.5.1
    kms_key_arn       = module.kms.manifest.arn    # ◀── same key, flows DOWN
  }
}
```

Trace of the KMS ARN:

1. The blueprint instantiates **one** key (via a component that owns
   `atoms/kms-key`) and reads `module.kms.manifest.arn`.
2. It passes that ARN **down** as a `config.kms_key_arn` field into
   `private-encrypted-bucket` and `audit-logging`.
3. Those components pass it **further down** into `atoms/s3-bucket`
   (`config.kms_key_arn`) and `atoms/cloudwatch-log-group`
   (`config.kms_key_arn`).
4. The atoms consume the ARN to set encryption — they never create the key.

This is the whole rule in action: the key is created once at the top, and the
reference flows strictly downward. No atom reaches up to find or make a key.

## When is it an atom, a component, or a blueprint?

Apply the **scope test**:

| Test question | Answer | Layer |
|---|---|---|
| Is it **one logical AWS resource** (+ its inseparable sub-resources)? | yes | **atom** |
| Is it **one capability** that needs **several atoms** wired together? | yes | **component** |
| Is it **one deployable environment** made of **several capabilities**? | yes | **blueprint** |

Rules of thumb:

- **Atom = single resource.** "A KMS key." "An S3 bucket." If you find yourself
  calling a `module` block, it is no longer an atom.
- **Tightly-coupled sub-resource exception:** sub-resources that cannot exist or
  make sense without the parent (bucket versioning, public-access-block, SSE
  config, a KMS alias) stay **inside** the atom. They are not separate atoms and
  do not promote the module to a component.
- **Component = single capability.** "A private encrypted bucket" =
  `s3-bucket` + `kms-key` + access-log bucket. It owns and wires those atoms but
  is not a whole environment.
- **Blueprint = single environment.** "A PCI three-tier web app." It wires
  capabilities (network, data, logging, compute) into something deployable per
  environment (dev/stage/prod, per market).

Quick heuristic: *raw `aws_*` resources ⇒ atom; `module` calls to atoms ⇒
component; `module` calls to components ⇒ blueprint.*

## Near-term roadmap

Candidate higher-layer modules to build on the planned atoms (`kms-key`,
`s3-bucket`, `security-group`, `vpc`, `subnet`, `iam-role`,
`cloudwatch-log-group`). One line each on what it composes.

### Candidate components

| Component | Composes | Capability |
|---|---|---|
| `private-encrypted-bucket` | `s3-bucket` (data) + `s3-bucket` (access-log target) + `kms-key` | Encrypted, private, access-logged bucket (Req 3, Req 10). |
| `audit-logging` | `cloudwatch-log-group` + `kms-key` (+ `iam-role` for log delivery) | Encrypted, 365-day-retained central log sink (Req 10). |
| `secure-network` | `vpc` + `subnet` (×N tiers) + `security-group` | Segmented VPC with flow logs and locked default SG (Req 1, Req 10). |
| `bastion-host` | `security-group` + `iam-role` (+ EC2 atom, future) | Hardened jump host with least-privilege role and tight SG (Req 1, Req 7, Req 8). |
| `alb-with-waf` | `security-group` (+ ALB & WAF atoms, future) | Public entry point with WAF and restricted SG ingress (Req 1, Req 6). |
| `encrypted-rds` | `kms-key` + `security-group` + `subnet` group (+ RDS atom, future) | Encrypted database, private subnets, no public access (Req 1, Req 3). |

### Candidate blueprints

| Blueprint | Composes | Environment |
|---|---|---|
| `pci-3tier-web-app` | `secure-network` + `alb-with-waf` + `encrypted-rds` + `private-encrypted-bucket` + `audit-logging` | Full PCI-scoped 3-tier web/app/data environment with central encryption and logging. |
| `secure-landing-zone` | `secure-network` + `audit-logging` + `iam-role` baseline (via a component) | Account baseline: segmented network, central audit logging, least-privilege roles for a new account/market. |

> Atoms marked "future" above are not yet in the planned set; the components
> that need them are listed so the dependency shape is clear, but they cannot be
> built until those atoms exist. Build order is bottom-up: atoms first, then the
> components that compose them, then blueprints.
