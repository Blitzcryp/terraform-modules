# Global configuration — set shared values ONCE

This example shows the repo's pattern for values reused across many modules, so
they are **never copy-pasted** into each module call.

## Global tags → `default_tags`

Define your organization/environment tags one time in a `locals` block and hand
them to the AWS provider's `default_tags`. AWS then stamps them onto **every**
resource created by **every** module — atoms, components, blueprints — with no
per-module wiring.

```hcl
locals {
  global_tags = {
    Project     = "paws"
    Environment = "prod"
    Owner       = "platform-team"
    CostCenter  = "CC-1234"
    Compliance  = "pci-dss"
    ManagedBy   = "terraform"
  }
}

provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = local.global_tags
  }
}
```

Each module still adds its own `Module = "<path>"` identity tag and honours any
per-resource `config.tags` you pass; AWS merges all layers (resource-level tags
win on key conflicts). You do **not** repeat `global_tags` in any module call.

## Other globals (region, name prefix, shared KMS key, network)

For non-tag values reused across many calls, set them once as locals and
reference them — or, at the blueprint layer, pass a single `globals` object on
`config` that the blueprint fans out to its components.

```hcl
locals {
  globals = {
    region        = "eu-central-1"
    name_prefix   = "paws-prod"
    kms_key_arn   = module.platform_kms.manifest.arn
    vpc_id        = module.network.manifest.vpc_id
    subnet_ids    = module.network.manifest.subnet_ids
  }
}
```

See `main.tf` in this directory for a runnable demonstration.
