output "vpc_id" {
  description = "Regional VPC ID."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "Regional VPC CIDR."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs for edge resources."
  value       = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs for EKS workloads."
  value       = values(aws_subnet.private)[*].id
}

output "database_subnet_ids" {
  description = "Private database subnet IDs."
  value       = values(aws_subnet.database)[*].id
}

output "nat_gateway_ids" {
  description = "NAT gateway IDs, empty when NAT is disabled."
  value       = values(aws_nat_gateway.this)[*].id
}

output "private_route_table_ids" {
  description = "Private route table IDs."
  value       = values(aws_route_table.private)[*].id
}

output "database_route_table_ids" {
  description = "Database route table IDs."
  value       = values(aws_route_table.database)[*].id
}
