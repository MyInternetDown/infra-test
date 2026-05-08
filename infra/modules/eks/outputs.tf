output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS API endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 cluster certificate authority data."
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID used for workload-to-database rules."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "EKS OIDC provider ARN for IRSA."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  description = "EKS OIDC issuer URL."
  value       = aws_iam_openid_connect_provider.this.url
}

output "node_role_arn" {
  description = "Managed node group IAM role ARN."
  value       = aws_iam_role.node.arn
}

output "ebs_csi_role_arn" {
  description = "IRSA role ARN for the EBS CSI driver add-on."
  value       = aws_iam_role.ebs_csi.arn
}
