resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-postgres"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name   = "${var.name}-postgres"
    Module = "rds-postgres"
  })
}

resource "aws_db_instance" "this" {
  identifier = "${var.name}-postgres"

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.database_name
  username = var.master_username

  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn

  allocated_storage     = var.allocated_storage_gb
  max_allocated_storage = var.max_allocated_storage_gb
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = false

  multi_az                    = var.multi_az
  backup_retention_period    = var.backup_retention_days
  backup_window              = "06:00-07:00"
  maintenance_window         = "sun:07:00-sun:08:00"
  auto_minor_version_upgrade = true

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-postgres-final"
  copy_tags_to_snapshot     = true

  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled ? var.kms_key_arn : null

  apply_immediately = false

  tags = merge(var.tags, {
    Name   = "${var.name}-postgres"
    Module = "rds-postgres"
  })
}
