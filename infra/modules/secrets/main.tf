resource "aws_secretsmanager_secret" "this" {
  for_each = var.secrets

  name                    = "${var.name_prefix}/${each.key}"
  description             = each.value.description
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = each.value.recovery_window_in_days

  tags = merge(var.tags, {
    Name   = "${var.name_prefix}/${each.key}"
    Module = "secrets"
  })
}

resource "aws_ssm_parameter" "this" {
  for_each = var.ssm_parameters

  name        = "/${var.name_prefix}/${each.key}"
  description = each.value.description
  type        = each.value.type
  value       = each.value.value
  key_id      = each.value.type == "SecureString" ? var.kms_key_arn : null

  tags = merge(var.tags, {
    Name   = "/${var.name_prefix}/${each.key}"
    Module = "secrets"
  })
}
