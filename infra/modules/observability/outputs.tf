output "alarm_topic_arn" {
  description = "SNS topic ARN for alarms."
  value       = aws_sns_topic.alarms.arn
}

output "log_group_names" {
  description = "Application log groups created by this module."
  value       = keys(aws_cloudwatch_log_group.application)
}
