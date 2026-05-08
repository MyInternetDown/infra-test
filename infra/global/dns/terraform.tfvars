root_domain_name   = "example.com"
create_public_zone = false

delegated_subdomains = {
  # "prod.example.com" = {
  #   name_servers = ["ns-000.awsdns-00.com", "ns-000.awsdns-00.net"]
  # }
}

tags = {
  Owner      = "platform-team"
  CostCenter = "shared"
}
