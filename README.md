# PAWS Terraform Modules — PCI DSS, secure by default

A layered library of AWS Terraform modules. Every module ships with
PCI-DSS-compliant defaults and a full override surface, so teams stay compliant
without getting blocked.

## Layers

```
aws/atoms/<family>/<name>  →  aws/components/<name>  →  aws/blueprints/<name>
1 AWS resource                1 capability               1 deployable environment
```

- **aws/atoms/`<service-family>`/** — thin wrappers over a single AWS resource,
  grouped by service family (e.g. `kms/kms-key`, `ecs/ecs-service`,
  `alb/lb-listener`). Take all dependencies as inputs; never call other modules.
- **aws/components/** — one capability built from atoms via `module` blocks only
  (e.g. `private-encrypted-bucket` = `s3-bucket` + `kms-key`).
- **aws/blueprints/** — a full environment built from components (e.g.
  `fargate-web-service`).

Source paths: component→atom `../../atoms/<family>/<name>`; blueprint→component
`../../components/<name>`.

## Global config (set shared values once)

Reused tags go in the AWS provider's `default_tags`, configured **once** at the
root — every resource in every module inherits them, no copy-paste. Each module
adds only its own `Module = "<path>"` identity tag. See
[`aws/examples/global-config`](./aws/examples/global-config).

## Design principle: secure by default, never stuck

Defaults are the compliant values. Every control is an overridable variable.
Disabling a control requires flipping an explicit, grep-able escape hatch
(`allow_*`) so weakened controls are intentional and auditable. See
[`CONVENTIONS.md`](./CONVENTIONS.md).

## Reference implementation

[`aws/atoms/kms/kms-key`](./aws/atoms/kms/kms-key) is the gold-standard atom —
copy its shape (file layout, `config`/`manifest`, secure defaults, escape hatch,
native tests).

## Quality gates

```bash
terraform fmt -recursive -check
tflint --recursive
checkov -d . --compact
terraform test          # per module
```

See [`docs/pci-dss-mapping.md`](./docs/pci-dss-mapping.md) for the control matrix.
