data "aws_route53_zone" "existing" {
  count = var.create_public_zone ? 0 : 1

  name         = var.root_domain_name
  private_zone = false
}

resource "aws_route53_zone" "public" {
  count = var.create_public_zone ? 1 : 0

  name = var.root_domain_name

  tags = merge(var.tags, {
    Name = var.root_domain_name
  })
}

locals {
  public_zone_id = var.create_public_zone ? aws_route53_zone.public[0].zone_id : data.aws_route53_zone.existing[0].zone_id
}

resource "aws_route53_record" "delegation" {
  for_each = var.delegated_subdomains

  zone_id = local.public_zone_id
  name    = each.key
  type    = "NS"
  ttl     = each.value.ttl
  records = each.value.name_servers
}
