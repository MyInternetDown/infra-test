module "regional_platform" {
  source = "../../../stacks/regional-platform"

  platform_name      = var.settings.platform_name
  environment        = var.settings.environment
  region             = var.settings.region
  domain_name        = var.settings.domain_name
  hosted_zone_name   = var.settings.hosted_zone_name
  vpc_cidr           = var.settings.vpc_cidr
  azs                = var.settings.azs
  public_subnet_cidrs   = var.settings.public_subnet_cidrs
  private_subnet_cidrs  = var.settings.private_subnet_cidrs
  database_subnet_cidrs = var.settings.database_subnet_cidrs

  enable_nat_gateway  = try(var.settings.enable_nat_gateway, true)
  single_nat_gateway  = try(var.settings.single_nat_gateway, false)
  enable_vpc_endpoints = try(var.settings.enable_vpc_endpoints, true)
  allowed_ingress_cidrs = try(var.settings.allowed_ingress_cidrs, ["0.0.0.0/0"])

  kubernetes_version                = var.settings.kubernetes_version
  eks_endpoint_public_access        = try(var.settings.eks_endpoint_public_access, true)
  eks_endpoint_public_access_cidrs  = try(var.settings.eks_endpoint_public_access_cidrs, [])
  node_groups                       = var.settings.node_groups

  database_name                 = var.settings.database_name
  db_instance_class             = var.settings.db_instance_class
  db_allocated_storage_gb       = var.settings.db_allocated_storage_gb
  db_max_allocated_storage_gb   = var.settings.db_max_allocated_storage_gb
  db_multi_az                   = var.settings.db_multi_az
  db_backup_retention_days      = var.settings.db_backup_retention_days
  db_deletion_protection        = var.settings.db_deletion_protection

  s3_buckets          = try(var.settings.s3_buckets, {})
  secret_names        = try(var.settings.secret_names, {})
  ssm_parameters      = try(var.settings.ssm_parameters, {})
  workload_irsa_roles = try(var.settings.workload_irsa_roles, {})

  enable_graph_database = try(var.settings.enable_graph_database, false)
  graph_database_mode   = try(var.settings.graph_database_mode, "neptune")
  graph_instance_class  = try(var.settings.graph_instance_class, "db.t4g.medium")
  graph_instance_count  = try(var.settings.graph_instance_count, 1)

  log_retention_days       = try(var.settings.log_retention_days, 30)
  alarm_email_endpoints    = try(var.settings.alarm_email_endpoints, [])
  monthly_budget_limit_usd = try(var.settings.monthly_budget_limit_usd, null)
  tags                     = try(var.settings.tags, {})
}
