output "alb_security_group_id" {
  description = "Security group ID for controlled public ingress."
  value       = aws_security_group.alb.id
}

output "rds_security_group_id" {
  description = "Security group ID for PostgreSQL."
  value       = aws_security_group.rds.id
}

output "graph_security_group_id" {
  description = "Security group ID for graph database access."
  value       = aws_security_group.graph.id
}
