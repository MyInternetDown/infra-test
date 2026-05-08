resource "aws_security_group" "alb" {
  name        = "${var.name}-alb"
  description = "Public ingress for controlled HTTP/HTTPS edge traffic."
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP redirect entrypoint"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ingress_cidrs
  }

  ingress {
    description = "HTTPS application entrypoint"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ingress_cidrs
  }

  egress {
    description = "Allow ALB to reach private targets."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name   = "${var.name}-alb"
    Module = "security"
  })
}

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-postgres"
  description = "PostgreSQL access from EKS workloads only."
  vpc_id      = var.vpc_id

  egress {
    description = "Return traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name   = "${var.name}-rds-postgres"
    Module = "security"
  })
}

resource "aws_security_group_rule" "rds_from_workloads" {
  type                     = "ingress"
  description              = "PostgreSQL from EKS workloads"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = var.workload_security_group_id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
}

resource "aws_security_group" "graph" {
  name        = "${var.name}-graph"
  description = "Graph database access from EKS workloads only."
  vpc_id      = var.vpc_id

  egress {
    description = "Return traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name   = "${var.name}-graph"
    Module = "security"
  })
}

resource "aws_security_group_rule" "neptune_from_workloads" {
  type                     = "ingress"
  description              = "AWS Neptune HTTPS/openCypher from EKS workloads"
  security_group_id        = aws_security_group.graph.id
  source_security_group_id = var.workload_security_group_id
  from_port                = 8182
  to_port                  = 8182
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "neo4j_bolt_from_workloads" {
  type                     = "ingress"
  description              = "Self-managed Neo4j Bolt from EKS workloads"
  security_group_id        = aws_security_group.graph.id
  source_security_group_id = var.workload_security_group_id
  from_port                = 7687
  to_port                  = 7687
  protocol                 = "tcp"
}
