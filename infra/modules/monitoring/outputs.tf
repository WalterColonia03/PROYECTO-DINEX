output "dashboard_name" {
  description = "Nombre del dashboard de CloudWatch"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_arn" {
  description = "ARN del dashboard de CloudWatch"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}

output "sns_topic_arn" {
  description = "ARN del topic SNS para alarmas"
  value       = var.create_sns_topic ? aws_sns_topic.alarms[0].arn : null
}
