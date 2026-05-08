output "public_zone_id" {
  description = "Route 53 public hosted zone ID."
  value       = local.public_zone_id
}

output "created_zone_name_servers" {
  description = "Name servers when this root creates the public hosted zone."
  value       = var.create_public_zone ? aws_route53_zone.public[0].name_servers : []
}
