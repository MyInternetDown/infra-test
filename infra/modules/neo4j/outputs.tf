output "mode" {
  description = "Selected graph database mode."
  value       = var.mode
}

output "endpoint" {
  description = "Graph database writer endpoint, null when disabled or self-managed."
  value       = local.create_neptune ? aws_neptune_cluster.this[0].endpoint : null
}

output "reader_endpoint" {
  description = "Graph database reader endpoint, null when disabled or self-managed."
  value       = local.create_neptune ? aws_neptune_cluster.this[0].reader_endpoint : null
}
