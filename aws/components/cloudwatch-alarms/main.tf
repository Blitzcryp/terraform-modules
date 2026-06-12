data "aws_caller_identity" "current" {}

locals {
  module_tags = {
    Module = "components/cloudwatch-alarms" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # ---------------------------------------------------------------------------
  # Topic / CMK ownership.
  # - Create an SNS topic only when the caller did not bring one.
  # - When we own the topic, create a dedicated CMK only when no BYO kms_key_arn.
  # ---------------------------------------------------------------------------
  create_topic = var.config.sns_topic_arn == null
  create_kms   = local.create_topic && var.config.kms_key_arn == null

  topic_name      = "${var.config.name_prefix}-security-alarms"
  effective_kms   = local.create_kms ? module.kms_key[0].manifest.arn : var.config.kms_key_arn
  alarm_topic_arn = local.create_topic ? module.topic[0].manifest.arn : var.config.sns_topic_arn

  # ---------------------------------------------------------------------------
  # CIS AWS Foundations / PCI DSS Req 10 monitoring baseline.
  # Each entry: a CloudWatch Logs filter pattern (matched against the CloudTrail
  # JSON log events) + the metric name the filter emits and the alarm watches.
  # All alarms use threshold>=1 over a single 5-minute period (Req 10.6).
  # ---------------------------------------------------------------------------
  baseline = {
    # CIS 3.1 — unauthorized API calls.
    unauthorized_api_calls = {
      metric_name = "UnauthorizedAPICalls"
      description = "CIS 3.1 / PCI Req 10.2.4: unauthorized API call detected."
      pattern     = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
    }
    # CIS 3.2 — console sign-in without MFA.
    console_signin_without_mfa = {
      metric_name = "ConsoleSigninWithoutMFA"
      description = "CIS 3.2 / PCI Req 8.4: console sign-in without MFA."
      pattern     = "{ ($.eventName = \"ConsoleLogin\") && ($.additionalEventData.MFAUsed != \"Yes\") && ($.userIdentity.type = \"IAMUser\") && ($.responseElements.ConsoleLogin = \"Success\") }"
    }
    # CIS 3.3 — usage of the root account.
    root_account_usage = {
      metric_name = "RootAccountUsage"
      description = "CIS 3.3 / PCI Req 7.2: root account used."
      pattern     = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
    }
    # CIS 3.4 — IAM policy changes.
    iam_policy_changes = {
      metric_name = "IAMPolicyChanges"
      description = "CIS 3.4 / PCI Req 10.2.5: IAM policy changed."
      pattern     = "{ ($.eventName=DeleteGroupPolicy) || ($.eventName=DeleteRolePolicy) || ($.eventName=DeleteUserPolicy) || ($.eventName=PutGroupPolicy) || ($.eventName=PutRolePolicy) || ($.eventName=PutUserPolicy) || ($.eventName=CreatePolicy) || ($.eventName=DeletePolicy) || ($.eventName=CreatePolicyVersion) || ($.eventName=DeletePolicyVersion) || ($.eventName=AttachRolePolicy) || ($.eventName=DetachRolePolicy) || ($.eventName=AttachUserPolicy) || ($.eventName=DetachUserPolicy) || ($.eventName=AttachGroupPolicy) || ($.eventName=DetachGroupPolicy) }"
    }
    # CIS 3.5 — CloudTrail configuration changes.
    cloudtrail_config_changes = {
      metric_name = "CloudTrailConfigChanges"
      description = "CIS 3.5 / PCI Req 10.5: CloudTrail configuration changed."
      pattern     = "{ ($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) || ($.eventName = StartLogging) || ($.eventName = StopLogging) }"
    }
    # CIS 3.6 — console authentication failures.
    console_auth_failures = {
      metric_name = "ConsoleAuthFailures"
      description = "CIS 3.6 / PCI Req 10.2.4: AWS Management Console authentication failure."
      pattern     = "{ ($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\") }"
    }
    # CIS 3.7 — disabling or scheduled deletion of customer-managed KMS keys.
    disable_or_delete_cmk = {
      metric_name = "DisableOrDeleteCMK"
      description = "CIS 3.7 / PCI Req 3.6: KMS CMK disabled or scheduled for deletion."
      pattern     = "{ ($.eventSource = kms.amazonaws.com) && (($.eventName = DisableKey) || ($.eventName = ScheduleKeyDeletion)) }"
    }
    # CIS 3.8 — S3 bucket policy changes.
    s3_bucket_policy_changes = {
      metric_name = "S3BucketPolicyChanges"
      description = "CIS 3.8 / PCI Req 10.2.5: S3 bucket policy changed."
      pattern     = "{ ($.eventSource = s3.amazonaws.com) && (($.eventName = PutBucketAcl) || ($.eventName = PutBucketPolicy) || ($.eventName = PutBucketCors) || ($.eventName = PutBucketLifecycle) || ($.eventName = PutBucketReplication) || ($.eventName = DeleteBucketPolicy) || ($.eventName = DeleteBucketCors) || ($.eventName = DeleteBucketLifecycle) || ($.eventName = DeleteBucketReplication)) }"
    }
    # CIS 3.9 — AWS Config configuration changes.
    aws_config_changes = {
      metric_name = "AWSConfigChanges"
      description = "CIS 3.9 / PCI Req 10.5: AWS Config configuration changed."
      pattern     = "{ ($.eventSource = config.amazonaws.com) && (($.eventName=StopConfigurationRecorder) || ($.eventName=DeleteDeliveryChannel) || ($.eventName=PutDeliveryChannel) || ($.eventName=PutConfigurationRecorder)) }"
    }
    # CIS 3.10 — security group changes.
    security_group_changes = {
      metric_name = "SecurityGroupChanges"
      description = "CIS 3.10 / PCI Req 1.1.1: security group changed."
      pattern     = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"
    }
    # CIS 3.11 — network ACL changes.
    nacl_changes = {
      metric_name = "NetworkACLChanges"
      description = "CIS 3.11 / PCI Req 1.1.1: network ACL changed."
      pattern     = "{ ($.eventName = CreateNetworkAcl) || ($.eventName = CreateNetworkAclEntry) || ($.eventName = DeleteNetworkAcl) || ($.eventName = DeleteNetworkAclEntry) || ($.eventName = ReplaceNetworkAclEntry) || ($.eventName = ReplaceNetworkAclAssociation) }"
    }
    # CIS 3.12 — network gateway changes.
    network_gateway_changes = {
      metric_name = "NetworkGatewayChanges"
      description = "CIS 3.12 / PCI Req 1.1.1: network gateway changed."
      pattern     = "{ ($.eventName = CreateCustomerGateway) || ($.eventName = DeleteCustomerGateway) || ($.eventName = AttachInternetGateway) || ($.eventName = CreateInternetGateway) || ($.eventName = DeleteInternetGateway) || ($.eventName = DetachInternetGateway) }"
    }
    # CIS 3.13 — route table changes.
    route_table_changes = {
      metric_name = "RouteTableChanges"
      description = "CIS 3.13 / PCI Req 1.1.1: route table changed."
      pattern     = "{ ($.eventName = CreateRoute) || ($.eventName = CreateRouteTable) || ($.eventName = ReplaceRoute) || ($.eventName = ReplaceRouteTableAssociation) || ($.eventName = DeleteRouteTable) || ($.eventName = DeleteRoute) || ($.eventName = DisassociateRouteTable) }"
    }
    # CIS 3.14 — VPC changes.
    vpc_changes = {
      metric_name = "VPCChanges"
      description = "CIS 3.14 / PCI Req 1.1.1: VPC changed."
      pattern     = "{ ($.eventName = CreateVpc) || ($.eventName = DeleteVpc) || ($.eventName = ModifyVpcAttribute) || ($.eventName = AcceptVpcPeeringConnection) || ($.eventName = CreateVpcPeeringConnection) || ($.eventName = DeleteVpcPeeringConnection) || ($.eventName = RejectVpcPeeringConnection) || ($.eventName = AttachClassicLinkVpc) || ($.eventName = DetachClassicLinkVpc) || ($.eventName = DisableVpcClassicLink) || ($.eventName = EnableVpcClassicLink) }"
    }
    # CIS 1.1 (Org) — AWS Organizations changes.
    organizations_changes = {
      metric_name = "OrganizationsChanges"
      description = "CIS / PCI Req 10.2.5: AWS Organizations changed."
      pattern     = "{ ($.eventSource = organizations.amazonaws.com) && (($.eventName = \"AcceptHandshake\") || ($.eventName = \"AttachPolicy\") || ($.eventName = \"CreateAccount\") || ($.eventName = \"CreateOrganizationalUnit\") || ($.eventName = \"CreatePolicy\") || ($.eventName = \"DeclineHandshake\") || ($.eventName = \"DeleteOrganization\") || ($.eventName = \"DeleteOrganizationalUnit\") || ($.eventName = \"DeletePolicy\") || ($.eventName = \"DetachPolicy\") || ($.eventName = \"DisablePolicyType\") || ($.eventName = \"EnablePolicyType\") || ($.eventName = \"InviteAccountToOrganization\") || ($.eventName = \"LeaveOrganization\") || ($.eventName = \"MoveAccount\") || ($.eventName = \"RemoveAccountFromOrganization\") || ($.eventName = \"UpdatePolicy\")) }"
    }
  }

  # Subset selection: null/empty enabled_alarms => the full baseline (secure default).
  selected_keys = (
    var.config.enabled_alarms == null || length(coalesce(var.config.enabled_alarms, [])) == 0
    ? keys(local.baseline)
    : var.config.enabled_alarms
  )

  enabled = { for k in local.selected_keys : k => local.baseline[k] }

  # ---------------------------------------------------------------------------
  # KMS key policy for the created CMK (only when this component owns the key).
  # Grants account-root admin PLUS CloudWatch service use, so CloudWatch can
  # publish alarm notifications through the CMK-encrypted SNS topic (least
  # privilege, PCI DSS Req 7). BYO keys are the caller's responsibility.
  # ---------------------------------------------------------------------------
  kms_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudWatchUseOfKey"
        Effect    = "Allow"
        Principal = { Service = "cloudwatch.amazonaws.com" }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*",
        ]
        Resource = "*"
      },
    ]
  })

  # Extra SNS topic-policy statement: CloudWatch alarms must be allowed to publish
  # to the (encrypted) topic. Scoped to this topic's ARN form.
  cloudwatch_publish_statement = {
    Sid       = "AllowCloudWatchAlarmsPublish"
    Effect    = "Allow"
    Principal = { Service = "cloudwatch.amazonaws.com" }
    Action    = "SNS:Publish"
    Resource  = "arn:aws:sns:*:${data.aws_caller_identity.current.account_id}:${local.topic_name}"
  }
}

# --- KMS CMK for the alarms topic (created only when we own the topic & no BYOK) ---
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms ? 1 : 0

  config = {
    description = "cloudwatch-alarms CMK for ${local.topic_name} (PCI DSS Req 3)"
    alias       = "cloudwatch-alarms/${var.config.name_prefix}"
    policy      = local.kms_policy
    tags        = var.config.tags
  }
}

# --- Encrypted SNS topic for alarm notifications (created unless BYO topic) -------
module "topic" {
  source = "../../atoms/sns/sns-topic"
  count  = local.create_topic ? 1 : 0

  config = {
    name        = local.topic_name
    kms_key_arn = local.effective_kms

    # Allow CloudWatch alarms to publish into the encrypted topic.
    additional_policy_statements = [local.cloudwatch_publish_statement]

    tags = var.config.tags
  }
}

# --- One log metric filter per enabled baseline event -----------------------------
module "metric_filter" {
  source   = "../../atoms/cloudwatch/cloudwatch-log-metric-filter"
  for_each = local.enabled

  config = {
    name           = "${var.config.name_prefix}-${each.key}"
    log_group_name = var.config.cloudtrail_log_group_name
    pattern        = each.value.pattern
    metric_name    = each.value.metric_name
    # Secure defaults inherited: namespace=CISBenchmark, value="1".
    tags = var.config.tags
  }
}

# --- One metric alarm per enabled baseline event, all wired to the SNS topic ------
module "metric_alarm" {
  source   = "../../atoms/cloudwatch/cloudwatch-metric-alarm"
  for_each = local.enabled

  config = {
    alarm_name          = "${var.config.name_prefix}-${each.key}"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 1
    metric_name         = each.value.metric_name
    namespace           = "CISBenchmark"
    period              = 300
    statistic           = "Sum"
    threshold           = 1
    alarm_description   = each.value.description

    # PCI DSS Req 10.6: every alarm notifies the security SNS topic.
    alarm_actions = [local.alarm_topic_arn]

    tags = var.config.tags
  }

  # The metric the alarm watches is produced by the matching filter.
  depends_on = [module.metric_filter]
}
