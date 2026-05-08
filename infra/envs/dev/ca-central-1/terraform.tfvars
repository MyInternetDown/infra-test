settings = {
  platform_name    = "product-platform"
  environment      = "dev"
  region           = "ca-central-1"
  domain_name      = "dev.ca-central-1.example.com"
  hosted_zone_name = "example.com"

  vpc_cidr              = "10.10.0.0/16"
  azs                   = ["ca-central-1a", "ca-central-1b"]
  public_subnet_cidrs   = ["10.10.0.0/24", "10.10.1.0/24"]
  private_subnet_cidrs  = ["10.10.10.0/24", "10.10.11.0/24"]
  database_subnet_cidrs = ["10.10.20.0/24", "10.10.21.0/24"]

  enable_nat_gateway       = true
  single_nat_gateway       = true
  enable_vpc_endpoints     = true
  allowed_ingress_cidrs    = ["0.0.0.0/0"]
  kubernetes_version       = "1.31"
  eks_endpoint_public_access = true
  eks_endpoint_public_access_cidrs = ["203.0.113.0/24"]

  node_groups = {
    general = {
      instance_types = ["t3.medium"]
      min_size       = 1
      desired_size   = 1
      max_size       = 3
      disk_size      = 50
      capacity_type  = "ON_DEMAND"
      labels         = { role = "general" }
    }
  }

  database_name               = "app"
  db_instance_class           = "db.t4g.micro"
  db_allocated_storage_gb     = 20
  db_max_allocated_storage_gb = 100
  db_multi_az                 = false
  db_backup_retention_days    = 3
  db_deletion_protection      = false

  secret_names = {
    "app/runtime" = "Application runtime secrets. Insert values with AWS CLI or a secret rotation workflow."
  }

  ssm_parameters = {
    "app/environment" = {
      description = "Non-sensitive application environment name."
      value       = "dev"
    }
  }

  enable_graph_database   = false
  graph_database_mode     = "neptune"
  log_retention_days      = 14
  alarm_email_endpoints   = ["devops@example.com"]
  monthly_budget_limit_usd = 300

  tags = {
    Owner      = "platform-team"
    CostCenter = "dev"
  }
}
