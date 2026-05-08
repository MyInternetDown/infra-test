data "aws_region" "current" {}

locals {
  az_map = {
    for index, az in var.azs : az => {
      public_cidr   = var.public_subnet_cidrs[index]
      private_cidr  = var.private_subnet_cidrs[index]
      database_cidr = var.database_subnet_cidrs[index]
    }
  }

  common_tags = merge(var.tags, {
    Module = "networking"
  })

  interface_endpoint_services = toset([
    "ec2messages",
    "ecr.api",
    "ecr.dkr",
    "logs",
    "secretsmanager",
    "ssm",
    "ssmmessages",
    "sts"
  ])
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = var.name
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = local.az_map

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value.public_cidr
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name                     = "${var.name}-public-${each.key}"
    Tier                     = "public"
    "kubernetes.io/role/elb" = "1"
  })
}

resource "aws_subnet" "private" {
  for_each = local.az_map

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value.private_cidr
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name                              = "${var.name}-private-${each.key}"
    Tier                              = "private"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_subnet" "database" {
  for_each = local.az_map

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value.database_cidr
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${var.name}-database-${each.key}"
    Tier = "database"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-public"
    Tier = "public"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  for_each = var.enable_nat_gateway ? (var.single_nat_gateway ? { (var.azs[0]) = local.az_map[var.azs[0]] } : local.az_map) : {}

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.name}-nat-${each.key}"
  })
}

resource "aws_nat_gateway" "this" {
  for_each = aws_eip.nat

  allocation_id = each.value.id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(local.common_tags, {
    Name = "${var.name}-nat-${each.key}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  for_each = local.az_map

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-private-${each.key}"
    Tier = "private"
  })
}

resource "aws_route" "private_nat" {
  for_each = var.enable_nat_gateway ? local.az_map : {}

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.this[var.azs[0]].id : aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table" "database" {
  for_each = local.az_map

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-database-${each.key}"
    Tier = "database"
  })
}

resource "aws_route_table_association" "database" {
  for_each = aws_subnet.database

  subnet_id      = each.value.id
  route_table_id = aws_route_table.database[each.key].id
}

resource "aws_security_group" "vpc_endpoints" {
  count = var.enable_vpc_endpoints ? 1 : 0

  name        = "${var.name}-vpc-endpoints"
  description = "Allow private subnets to reach AWS interface endpoints over HTTPS."
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from inside VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Return traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-vpc-endpoints"
  })
}

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(values(aws_route_table.private)[*].id, values(aws_route_table.database)[*].id)

  tags = merge(local.common_tags, {
    Name = "${var.name}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "interface" {
  for_each = var.enable_vpc_endpoints ? local.interface_endpoint_services : toset([])

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.name}-${replace(each.key, ".", "-")}-endpoint"
  })
}
