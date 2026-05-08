locals {
  provider_tags = merge({
    Platform    = try(var.settings.platform_name, "unknown")
    Environment = try(var.settings.environment, "unknown")
    Region      = try(var.settings.region, "unknown")
    ManagedBy   = "terraform"
  }, try(var.settings.tags, {}))
}
