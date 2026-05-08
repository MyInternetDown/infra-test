resource "aws_sns_topic" "alarms" {
  name              = "${var.name}-alarms"
  kms_master_key_id = var.kms_key_arn

  tags = merge(var.tags, {
    Name   = "${var.name}-alarms"
    Module = "observability"
  })
}

resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.sns_email_endpoints)

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = each.key
}

resource "aws_cloudwatch_log_group" "application" {
  for_each = toset(var.log_group_names)

  name              = each.key
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(var.tags, {
    Name   = each.key
    Module = "observability"
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  count = var.rds_instance_id == null ? 0 : 1

  alarm_name          = "${var.name}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU has been above 80 percent for 15 minutes."
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  count = var.rds_instance_id == null ? 0 : 1

  alarm_name          = "${var.name}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10737418240
  alarm_description   = "RDS free storage is below 10 GiB."
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = var.tags
}

resource "aws_budgets_budget" "monthly" {
  count = var.monthly_budget_limit_usd == null ? 0 : 1

  name         = "${var.name}-monthly-budget"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_limit_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  dynamic "notification" {
    for_each = length(var.sns_email_endpoints) == 0 ? [] : [1]

    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = 80
      threshold_type             = "PERCENTAGE"
      notification_type          = "FORECASTED"
      subscriber_email_addresses = var.sns_email_endpoints
    }
  }
}
