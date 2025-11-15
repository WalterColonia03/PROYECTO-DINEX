# Outputs del módulo API Gateway

output "api_id" {
  description = "ID de la API Gateway"
  value       = aws_api_gateway_rest_api.this.id
}

output "api_name" {
  description = "Nombre de la API Gateway"
  value       = aws_api_gateway_rest_api.this.name
}

output "api_arn" {
  description = "ARN de la API Gateway"
  value       = aws_api_gateway_rest_api.this.arn
}

output "api_execution_arn" {
  description = "ARN de ejecución de la API Gateway"
  value       = aws_api_gateway_rest_api.this.execution_arn
}

output "api_endpoint" {
  description = "Endpoint de la API Gateway"
  value       = aws_api_gateway_stage.this.invoke_url
}

output "stage_name" {
  description = "Nombre del stage"
  value       = aws_api_gateway_stage.this.stage_name
}

output "api_key" {
  description = "API Key (si está creada)"
  value       = var.create_api_key ? aws_api_gateway_api_key.this[0].value : null
  sensitive   = true
}

output "log_group_name" {
  description = "Nombre del CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.api_gateway.name
}
