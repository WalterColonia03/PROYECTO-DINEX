# Outputs para PRODUCCIÓN (idénticos a DEV)

output "api_gateway_url" {
  description = "URL del API Gateway"
  value       = "Configurar después del deploy"
}

output "cloudwatch_dashboard_name" {
  description = "Nombre del dashboard"
  value       = "dinex-prod-dashboard"
}
