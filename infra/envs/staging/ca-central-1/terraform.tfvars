settings = {
  platform_name    = "product-platform"
  environment      = "staging"
  region           = "ca-central-1"
  domain_name      = "staging.ca-central-1.example.com"
  hosted_zone_name = "example.com"

  vpc_cidr              = "10.20.0.0/16"
  azs                   = ["ca-central-1a", "ca-central-1b"]
  public_subnet_cidrs   = ["10.20.0.0/24", "10.20.1.0/24"]
  private_subnet_cidrs  = ["10.20.10.0/24", "10.20.11.0/24"]
  database_subnet_cidrs = ["10.20.20.0/24", "10.20.21.0/24"]

  enable_nat_gateway                 = true
  single_nat_gateway                 = false
  enable_vpc_endpoints               = true
  allowed_ingress_cidrs              = ["0.0.0.0/0"]
  kubernetes_version                 = "1.31"
  eks_endpoint_public_access         = true
  eks_endpoint_public_access_cidrs   = ["203.0.113.0/24"]

  node_groups = {
    general = {
      instance_types = ["t3.large"]
      min_size       = 2
      desired_size   = 2
      max_size       = 5
      disk_size      = 80
      capacity_type  = "ON_DEMAND"
      labels         = { role = "general" }
    }
  }

  database_name               = "app"
  db_instance_class           = "db.t4g.small"
  db_allocated_storage_gb     = 50
  db_max_allocated_storage_gb = 200
  db_multi_az                 = true
  db_backup_retention_days    = 7
  db_deletion_protection      = true

  secret_names = {
    "app/runtime" = "Application runtime secrets. Insert values with AWS CLI or a secret rotation workflow."
  }

  ssm_parameters = {
    "app/environment" = {
      description = "Non-sensitive application environment name."
      value       = "staging"
    }
  }

  enable_graph_database    = false
  graph_database_mode      = "neptune"
  log_retention_days       = 30
  alarm_email_endpoints    = ["devops@example.com"]
  monthly_budget_limit_usd = 1000

  tags = {
    Owner      = "platform-team"
    CostCenter = "staging"
  }
}
