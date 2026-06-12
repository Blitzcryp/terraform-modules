output "manifest" {
  description = "All outputs of the mq (Amazon MQ) component, collected on a single object."
  value = {
    # nonsensitive() because the mq-broker atom's config is sensitive, which
    # taints all its outputs; these identifiers carry no secret material.
    broker_id  = nonsensitive(module.mq_broker.manifest.id)
    broker_arn = nonsensitive(module.mq_broker.manifest.arn)
    # Broker connection endpoints (e.g. ssl/amqps URIs). nonsensitive() because
    # the mq-broker atom's config is sensitive, which taints its outputs; the
    # endpoints themselves carry no secret material.
    broker_endpoints = nonsensitive(module.mq_broker.manifest.endpoints)

    security_group_id = nonsensitive(module.security_group.manifest.id)

    # The effective key the broker is encrypted with (created or BYO). Derived
    # from the sensitive config, so unwrapped — it carries no secret material.
    kms_key_arn = nonsensitive(local.effective_kms_arn)
  }
}
