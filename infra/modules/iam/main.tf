locals {
  oidc_provider_host = var.oidc_provider_url == null ? null : replace(var.oidc_provider_url, "https://", "")
  github_subjects = var.github_repository == null ? [] : [
    for ref in var.github_allowed_refs : "repo:${var.github_repository}:ref:${ref}"
  ]
}

data "aws_iam_policy_document" "irsa_assume_role" {
  for_each = var.workload_irsa_roles

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_host}:sub"
      values   = ["system:serviceaccount:${each.value.namespace}:${each.value.service_account}"]
    }
  }
}

resource "aws_iam_role" "irsa" {
  for_each = var.workload_irsa_roles

  name               = "${var.name_prefix}-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume_role[each.key].json

  tags = merge(var.tags, {
    Name   = "${var.name_prefix}-${each.key}"
    Module = "iam"
  })
}

resource "aws_iam_policy" "irsa" {
  for_each = var.workload_irsa_roles

  name   = "${var.name_prefix}-${each.key}"
  policy = each.value.policy_json

  tags = merge(var.tags, {
    Name   = "${var.name_prefix}-${each.key}"
    Module = "iam"
  })
}

resource "aws_iam_role_policy_attachment" "irsa" {
  for_each = var.workload_irsa_roles

  role       = aws_iam_role.irsa[each.key].name
  policy_arn = aws_iam_policy.irsa[each.key].arn
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.github_oidc_enabled ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.github_oidc_thumbprints

  tags = merge(var.tags, {
    Name   = "${var.name_prefix}-github-actions"
    Module = "iam"
  })
}

data "aws_iam_policy_document" "github_assume_role" {
  count = var.github_oidc_enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.github_subjects
    }
  }
}

resource "aws_iam_role" "github_deploy" {
  count = var.github_oidc_enabled ? 1 : 0

  name               = "${var.name_prefix}-github-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role[0].json

  tags = merge(var.tags, {
    Name   = "${var.name_prefix}-github-deploy"
    Module = "iam"
  })
}

resource "aws_iam_policy" "github_deploy" {
  count = var.github_oidc_enabled && var.github_attach_deploy_policy ? 1 : 0

  name   = "${var.name_prefix}-github-deploy"
  policy = var.github_deploy_policy_json

  tags = merge(var.tags, {
    Name   = "${var.name_prefix}-github-deploy"
    Module = "iam"
  })
}

resource "aws_iam_role_policy_attachment" "github_deploy" {
  count = var.github_oidc_enabled && var.github_attach_deploy_policy ? 1 : 0

  role       = aws_iam_role.github_deploy[0].name
  policy_arn = aws_iam_policy.github_deploy[0].arn
}
