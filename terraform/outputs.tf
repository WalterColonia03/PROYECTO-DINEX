# Outputs del proyecto - Valores importantes generados después del deployment

# URL del API Gateway
# Esta URL se usará para hacer requests HTTP al sistema
output "api_endpoint" {
  description = "URL del API Gateway para hacer requests"
  value       = "${aws_apigatewayv2_api.api.api_endpoint}/${var.environment}"
}

# Ejemplo de uso del API
output "api_usage_examples" {
  description = "Ejemplos de cómo usar el API"
  value = <<-EOT

  Ejemplos de uso del API:

  1. Crear/Actualizar tracking:
     curl -X POST ${aws_apigatewayv2_api.api.api_endpoint}/${var.environment}/tracking \
       -H "Content-Type: application/json" \
       -d '{
         "tracking_id": "TRK001",
         "package_id": "PKG001",
         "location": "Lima - Almacén Principal",
         "latitude": -12.0464,
         "longitude": -77.0428,
         "status": "IN_TRANSIT"
       }'

  2. Consultar tracking:
     curl "${aws_apigatewayv2_api.api.api_endpoint}/${var.environment}/tracking?tracking_id=TRK001"

  3. Health check:
     curl "${aws_apigatewayv2_api.api.api_endpoint}/${var.environment}/health"

  EOT
}

# Nombre de la tabla DynamoDB
output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB"
  value       = aws_dynamodb_table.tracking.name
}

# ARN de la tabla DynamoDB
output "dynamodb_table_arn" {
  description = "ARN de la tabla DynamoDB"
  value       = aws_dynamodb_table.tracking.arn
}

# Nombre de la función Lambda de tracking
output "lambda_tracking_function_name" {
  description = "Nombre de la función Lambda de tracking"
  value       = aws_lambda_function.tracking.function_name
}

# ARN de la función Lambda de tracking
output "lambda_tracking_arn" {
  description = "ARN de la función Lambda de tracking"
  value       = aws_lambda_function.tracking.arn
}

# Nombre de la función Lambda de notifications
output "lambda_notifications_function_name" {
  description = "Nombre de la función Lambda de notificaciones"
  value       = aws_lambda_function.notifications.function_name
}

# ARN del SNS Topic
output "sns_topic_arn" {
  description = "ARN del SNS Topic para notificaciones"
  value       = aws_sns_topic.notifications.arn
}

# Nombre del CloudWatch Dashboard
output "dashboard_name" {
  description = "Nombre del CloudWatch Dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

# URL del Dashboard en la consola de AWS
output "dashboard_url" {
  description = "URL del CloudWatch Dashboard en la consola de AWS"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

# Información de costos estimados
output "cost_estimate" {
  description = "Estimación de costos mensuales"
  value = <<-EOT

  Estimación de costos mensuales (Free Tier):

  - Lambda: $0 (1M requests gratis)
  - DynamoDB: $0 (25 GB + 25 RCU/WCU gratis)
  - API Gateway: $3.50 (después de 1M gratis)
  - CloudWatch: $2 (después de 5 GB logs gratis)
  - SNS: $0 (1M publicaciones gratis)

  TOTAL ESTIMADO: $5-10/mes en ambiente ${var.environment}

  Nota: Los costos reales dependen del uso. Configurar AWS Budgets para alertas.

  EOT
}

# Información del ambiente
output "environment_info" {
  description = "Información del ambiente desplegado"
  value = {
    project     = var.project
    environment = var.environment
    region      = var.aws_region
    student     = var.student_name
  }
}

# URLs de logs en CloudWatch
output "cloudwatch_logs" {
  description = "URLs para ver logs en CloudWatch"
  value = {
    tracking_lambda      = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/${replace(aws_cloudwatch_log_group.tracking.name, "/", "$252F")}"
    notifications_lambda = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/${replace(aws_cloudwatch_log_group.notifications.name, "/", "$252F")}"
    api_gateway          = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/${replace(aws_cloudwatch_log_group.api_gateway.name, "/", "$252F")}"
  }
}
