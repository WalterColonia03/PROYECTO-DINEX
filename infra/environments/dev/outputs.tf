# Outputs del ambiente DEV

# API Gateway
output "api_gateway_url" {
  description = "URL del API Gateway"
  value       = module.api_gateway.api_endpoint
}

output "api_gateway_id" {
  description = "ID del API Gateway"
  value       = module.api_gateway.api_id
}

# DynamoDB Tables
output "orders_table_name" {
  description = "Nombre de la tabla de órdenes"
  value       = module.orders_table.table_name
}

output "tracking_table_name" {
  description = "Nombre de la tabla de tracking"
  value       = module.tracking_table.table_name
}

output "routes_table_name" {
  description = "Nombre de la tabla de rutas"
  value       = module.routes_table.table_name
}

# Lambda Functions
output "lambda_process_orders_arn" {
  description = "ARN de la función Lambda para procesar órdenes"
  value       = module.lambda_process_orders.function_arn
}

output "lambda_update_tracking_arn" {
  description = "ARN de la función Lambda para tracking"
  value       = module.lambda_update_tracking.function_arn
}

output "lambda_optimize_routes_arn" {
  description = "ARN de la función Lambda para optimizar rutas"
  value       = module.lambda_optimize_routes.function_arn
}

output "lambda_send_notifications_arn" {
  description = "ARN de la función Lambda para notificaciones"
  value       = module.lambda_send_notifications.function_arn
}

# SQS Queues
output "orders_queue_url" {
  description = "URL de la cola de órdenes"
  value       = module.orders_queue.queue_url
}

output "notifications_queue_url" {
  description = "URL de la cola de notificaciones"
  value       = module.notifications_queue.queue_url
}

# Monitoring
output "cloudwatch_dashboard_name" {
  description = "Nombre del dashboard de CloudWatch"
  value       = module.monitoring.dashboard_name
}

output "sns_topic_arn" {
  description = "ARN del SNS topic para alarmas"
  value       = module.monitoring.sns_topic_arn
}

# Información útil para testing
output "testing_info" {
  description = "Información para testing"
  value = <<-EOT

    ========================================
    DINEX - Ambiente de DESARROLLO
    ========================================

    API Gateway:
      URL: ${module.api_gateway.api_endpoint}

    Endpoints disponibles:
      - POST ${module.api_gateway.api_endpoint}/orders (Crear orden)
      - GET  ${module.api_gateway.api_endpoint}/orders (Listar órdenes)
      - GET  ${module.api_gateway.api_endpoint}/tracking (Consultar tracking)
      - PUT  ${module.api_gateway.api_endpoint}/tracking (Actualizar tracking)
      - POST ${module.api_gateway.api_endpoint}/routes (Optimizar rutas)

    CloudWatch Dashboard:
      https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${module.monitoring.dashboard_name}

    Ejemplo de curl:
      curl -X POST ${module.api_gateway.api_endpoint}/orders \
        -H "Content-Type: application/json" \
        -d '{"customer_id":"CUST001","products":[{"sku":"PROD123","quantity":2}]}'

    Ver logs:
      aws logs tail /aws/lambda/${module.lambda_process_orders.function_name} --follow

  EOT
}
