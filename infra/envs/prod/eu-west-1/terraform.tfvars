settings = {
  platform_name    = "product-platform"
  environment      = "prod"
  region           = "eu-west-1"
  domain_name      = "eu-west-1.prod.example.com"
  hosted_zone_name = "example.com"

  vpc_cidr              = "10.120.0.0/16"
  azs                   = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  public_subnet_cidrs   = ["10.120.0.0/24", "10.120.1.0/24", "10.120.2.0/24"]
  private_subnet_cidrs  = ["10.120.10.0/24", "10.120.11.0/24", "10.120.12.0/24"]
  database_subnet_cidrs = ["10.120.20.0/24", "10.120.21.0/24", "10.120.22.0/24"]

  enable_nat_gateway               = true
  single_nat_gateway               = false
  enable_vpc_endpoints             = true
  allowed_ingress_cidrs            = ["0.0.0.0/0"]
  kubernetes_version               = "1.31"
  eks_endpoint_public_access       = true
  eks_endpoint_public_access_cidrs = ["203.0.113.0/24"]

  node_groups = {
    general = {
      instance_types = ["m7i.large"]
      min_size       = 3
      desired_size   = 3
      max_size       = 10
      disk_size      = 100
      capacity_type  = "ON_DEMAND"
      labels         = { role = "general" }
    }
  }

  database_name               = "app"
  db_instance_class           = "db.m7g.large"
  db_allocated_storage_gb     = 100
  db_max_allocated_storage_gb = 1000
  db_multi_az                 = true
  db_backup_retention_days    = 14
  db_deletion_protection      = true

  secret_names = {
    "app/runtime" = "Application runtime secrets. Insert values with AWS CLI or a secret rotation workflow."
  }

  ssm_parameters = {
    "app/environment" = {
      description = "Non-sensitive application environment name."
      value       = "prod"
    }
  }

  enable_graph_database    = true
  graph_database_mode      = "neptune"
  graph_instance_class     = "db.r6g.large"
  graph_instance_count     = 2
  log_retention_days       = 90
  alarm_email_endpoints    = ["devops@example.com"]
  monthly_budget_limit_usd = 5000

  tags = {
    Owner      = "platform-team"
    CostCenter = "prod"
  }
}
