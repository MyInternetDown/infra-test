output "vpc_id" {
  description = "Regional VPC ID."
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "Private workload subnet IDs."
  value       = module.networking.private_subnet_ids
}

output "database_subnet_ids" {
  description = "Private database subnet IDs."
  value       = module.networking.database_subnet_ids
}

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint."
  value       = module.eks.cluster_endpoint
}

output "rds_postgres_endpoint" {
  description = "RDS PostgreSQL endpoint."
  value       = module.rds_postgres.endpoint
}

output "rds_master_secret_arn" {
  description = "Secrets Manager ARN for RDS-managed master password."
  value       = module.rds_postgres.master_user_secret_arn
  sensitive   = true
}

output "s3_bucket_names" {
  description = "Application S3 bucket names."
  value       = module.s3.bucket_names
}

output "ingress_certificate_arn" {
  description = "ACM certificate ARN for regional ingress."
  value       = module.ingress.certificate_arn
}

output "alb_ingress_annotations" {
  description = "Suggested Kubernetes Ingress annotations for AWS Load Balancer Controller."
  value       = module.ingress.alb_ingress_annotations
}

output "graph_database_endpoint" {
  description = "Graph database endpoint, null when disabled or self-managed."
  value       = module.graph_database.endpoint
}

output "irsa_role_arns" {
  description = "IRSA role ARNs."
  value       = module.iam.irsa_role_arns
}

output "ebs_csi_role_arn" {
  description = "IRSA role ARN for the EBS CSI driver."
  value       = module.eks.ebs_csi_role_arn
}

output "alarm_topic_arn" {
  description = "SNS topic ARN for regional alarms."
  value       = module.observability.alarm_topic_arn
}
