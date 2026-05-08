data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "this" {
  for_each = var.keys

  statement {
    sid     = "EnableAccountAdministration"
    actions = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(each.value.service_principals) == 0 ? [] : [each.value.service_principals]

    content {
      sid = "AllowServiceUse"
      actions = [
        "kms:CreateGrant",
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*"
      ]

      principals {
        type        = "Service"
        identifiers = statement.value
      }

      resources = ["*"]

      condition {
        test     = "StringEquals"
        variable = "kms:CallerAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
    }
  }
}

resource "aws_kms_key" "this" {
  for_each = var.keys

  description             = each.value.description
  deletion_window_in_days = each.value.deletion_window_in_days
  enable_key_rotation     = each.value.enable_key_rotation
  policy                  = data.aws_iam_policy_document.this[each.key].json

  tags = merge(var.tags, {
    Name   = "${var.name_prefix}-${each.key}"
    Module = "kms"
  })
}

resource "aws_kms_alias" "this" {
  for_each = aws_kms_key.this

  name          = "alias/${var.name_prefix}-${each.key}"
  target_key_id = each.value.key_id
}
