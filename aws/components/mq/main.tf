locals {
  module_tags = {
    Module = "components/mq" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Whether this component owns the CMK. A BYO key ARN skips the kms-key atom and
  # encrypts the broker with the caller's key.
  create_kms        = var.config.kms_key_arn == null
  effective_kms_arn = local.create_kms ? module.kms_key[0].manifest.arn : var.config.kms_key_arn

  # Engine-appropriate TLS client ports (PCI DSS Req 4: secure transport only).
  # ActiveMQ: OpenWire SSL 61617 + web console SSL 8162.
  # RabbitMQ: AMQPS 5671.
  broker_tls_ports = var.config.engine_type == "RabbitMQ" ? [
    { from = 5671, to = 5671, desc = "RabbitMQ AMQPS" },
    ] : [
    { from = 61617, to = 61617, desc = "ActiveMQ OpenWire SSL" },
    { from = 8162, to = 8162, desc = "ActiveMQ console SSL" },
  ]

  # Ingress from supplied client SGs and CIDRs only — no public (0.0.0.0/0)
  # ingress is ever generated (PCI DSS Req 1). One rule per source x port.
  sg_ingress_rules = concat(
    flatten([
      for sg in var.config.allowed_security_group_ids : [
        for p in local.broker_tls_ports : {
          description                  = "${p.desc} from client SG ${sg}"
          ip_protocol                  = "tcp"
          from_port                    = p.from
          to_port                      = p.to
          referenced_security_group_id = sg
        }
      ]
    ]),
    flatten([
      for cidr in var.config.allowed_cidrs : [
        for p in local.broker_tls_ports : {
          description = "${p.desc} from ${cidr}"
          ip_protocol = "tcp"
          from_port   = p.from
          to_port     = p.to
          cidr_ipv4   = cidr
        }
      ]
    ]),
  )
}

# --- Broker security group (no public ingress; broker TLS ports only) ---------
module "security_group" {
  source = "../../atoms/vpc/security-group"

  config = {
    name        = "${var.config.broker_name}-mq"
    vpc_id      = var.config.vpc_id
    description = "Amazon MQ broker SG for ${var.config.broker_name} (TLS clients only)"

    ingress_rules = local.sg_ingress_rules
    # config.tags is non-sensitive metadata; nonsensitive() because the whole
    # config object is marked sensitive (it carries broker passwords).
    tags = nonsensitive(var.config.tags)
  }
}

# --- KMS CMK (created only when no BYO key is supplied) -----------------------
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms ? 1 : 0

  config = {
    description = "Amazon MQ CMK for ${var.config.broker_name} (PCI DSS Req 3)"
    alias       = "mq/${var.config.broker_name}"
    tags        = nonsensitive(var.config.tags)
  }
}

# --- Amazon MQ broker (private, CMK at rest, general + audit logs) ------------
module "mq_broker" {
  source = "../../atoms/mq/mq-broker"

  config = {
    broker_name        = var.config.broker_name
    engine_type        = var.config.engine_type
    host_instance_type = var.config.host_instance_type
    deployment_mode    = var.config.deployment_mode
    subnet_ids         = var.config.subnet_ids
    security_groups    = [module.security_group.manifest.id]

    # publicly_accessible defaults to false in the atom (PCI DSS Req 1).

    # Encryption at rest with the effective CMK (created or BYO); never null, so
    # the atom's CMK precondition is satisfied without its escape hatch.
    kms_key_arn = local.effective_kms_arn

    # general + audit logs default to true in the atom (PCI DSS Req 10).

    # Broker users (PCI DSS Req 8): passwords are supplied by the caller from a
    # secrets manager and flow straight through; this component never hardcodes one.
    users = var.config.users

    tags = nonsensitive(var.config.tags)
  }
}
