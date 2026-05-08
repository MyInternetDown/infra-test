locals {
  create_neptune = var.enabled && var.mode == "neptune"
}

resource "aws_neptune_subnet_group" "this" {
  count = local.create_neptune ? 1 : 0

  name       = "${var.name}-graph"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name   = "${var.name}-graph"
    Module = "neo4j"
  })
}

resource "aws_neptune_cluster" "this" {
  count = local.create_neptune ? 1 : 0

  cluster_identifier                  = "${var.name}-graph"
  engine                              = "neptune"
  neptune_subnet_group_name           = aws_neptune_subnet_group.this[0].name
  vpc_security_group_ids              = var.security_group_ids
  storage_encrypted                   = true
  kms_key_arn                         = var.kms_key_arn
  iam_database_authentication_enabled = true
  backup_retention_period             = var.backup_retention_days
  preferred_backup_window             = "05:00-06:00"
  preferred_maintenance_window        = "sun:06:00-sun:07:00"
  deletion_protection                 = var.deletion_protection
  skip_final_snapshot                 = var.skip_final_snapshot
  final_snapshot_identifier           = var.skip_final_snapshot ? null : "${var.name}-graph-final"
  apply_immediately                   = false

  tags = merge(var.tags, {
    Name   = "${var.name}-graph"
    Module = "neo4j"
  })
}

resource "aws_neptune_cluster_instance" "this" {
  count = local.create_neptune ? var.instance_count : 0

  identifier         = "${var.name}-graph-${count.index + 1}"
  cluster_identifier = aws_neptune_cluster.this[0].id
  engine             = "neptune"
  instance_class     = var.instance_class

  tags = merge(var.tags, {
    Name   = "${var.name}-graph-${count.index + 1}"
    Module = "neo4j"
  })
}
