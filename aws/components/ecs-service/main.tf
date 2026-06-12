locals {
  module_tags = {
    Module = "components/ecs-service" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  log_group_name = "/ecs/${var.config.name}/app"

  load_balanced = var.config.target_group_arn != null

  # Cluster name parsed out of the cluster ARN
  # (arn:aws:ecs:<region>:<account>:cluster/<name>). Needed to build the
  # autoscaling target's resource_id "service/<cluster-name>/<service-name>".
  cluster_name = regex("cluster/(?P<name>.+)$", var.config.cluster_arn)["name"]

  autoscaling_resource_id = "service/${local.cluster_name}/${var.config.name}"

  # load_balancers list handed to the ECS service atom (empty unless LB-wired).
  load_balancers = local.load_balanced ? [{
    target_group_arn = var.config.target_group_arn
    container_name   = var.config.container_name
    container_port   = var.config.container_port
  }] : []
}

# Root-level guard so an insecure public-IP choice fails fast at this layer with
# a clear, auditable message (PCI DSS Req 1). The ecs-service atom also enforces
# this, but a root-managed resource lets the precondition be asserted in tests.
resource "terraform_data" "guards" {
  input = var.config.name

  lifecycle {
    precondition {
      condition     = !var.config.assign_public_ip || var.config.allow_public_ip
      error_message = "assign_public_ip=true without config.allow_public_ip=true. Tasks should stay in private subnets. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}

# --- Encrypted CloudWatch log group (app / container logs) --------------------
module "log_group" {
  source = "../../atoms/cloudwatch/cloudwatch-log-group"

  config = {
    name              = local.log_group_name
    kms_key_arn       = var.config.kms_key_arn # null rejected unless allow_unencrypted_logs=true
    retention_in_days = var.config.log_retention_days
    tags              = var.config.tags

    # Escape hatch passed straight through to the atom.
    allow_unencrypted = var.config.allow_unencrypted_logs
  }
}

# --- Service security group (no public ingress) -------------------------------
module "security_group" {
  source = "../../atoms/vpc/security-group"

  config = {
    name        = "${var.config.name}-svc"
    vpc_id      = var.config.vpc_id
    description = "ECS service SG for ${var.config.name}"

    # Caller-supplied ingress (typically referencing the LB SG); empty = no
    # ingress. The atom rejects public ingress unless its escape hatch is set.
    ingress_rules = var.config.ingress_rules

    # Egress to anywhere (HTTPS to pull images, reach Secrets Manager, etc.).
    # Documented per PCI DSS Req 1; tasks live in private subnets.
    egress_rules = [{
      description = "Allow all outbound from ECS tasks (image pulls, AWS APIs)"
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }]

    tags = var.config.tags
  }
}

# --- ECS task definition ------------------------------------------------------
module "task_definition" {
  source = "../../atoms/ecs/ecs-task-definition"

  config = {
    family                = var.config.name
    container_definitions = var.config.container_definitions
    cpu                   = var.config.cpu
    memory                = var.config.memory
    execution_role_arn    = var.config.execution_role_arn
    task_role_arn         = var.config.task_role_arn
    tags                  = var.config.tags
    # awsvpc + FARGATE secure defaults inherited from the atom.
  }
}

# --- ECS service --------------------------------------------------------------
module "ecs_service" {
  source = "../../atoms/ecs/ecs-service"

  config = {
    name               = var.config.name
    cluster_arn        = var.config.cluster_arn
    task_definition    = module.task_definition.manifest.arn
    subnet_ids         = var.config.subnet_ids
    security_group_ids = [module.security_group.manifest.id]
    desired_count      = var.config.desired_count

    # Private networking by default. The public-IP escape hatch is enforced at
    # this component layer by terraform_data.guards (the single, auditable gate);
    # we therefore satisfy the atom's own precondition so it does not double-fail
    # on the same misconfiguration. A public IP still requires the caller to set
    # config.allow_public_ip (checked by the guard above).
    assign_public_ip = var.config.assign_public_ip
    allow_public_ip  = var.config.assign_public_ip

    load_balancers = local.load_balancers

    # Deployment circuit-breaker rollback is the atom default (ECS controller).
    tags = var.config.tags
  }
}

# --- Target-tracking autoscaling (created only when enabled) ------------------
module "autoscaling" {
  source = "../../atoms/ecs/app-autoscaling"
  count  = var.config.enable_autoscaling ? 1 : 0

  config = {
    # resource_id references the service via cluster + service name. Depends on
    # the service existing first.
    resource_id   = local.autoscaling_resource_id
    min_capacity  = var.config.min_capacity
    max_capacity  = var.config.max_capacity
    target_cpu    = var.config.target_cpu
    target_memory = var.config.target_memory
    tags          = var.config.tags
  }

  depends_on = [module.ecs_service]
}
