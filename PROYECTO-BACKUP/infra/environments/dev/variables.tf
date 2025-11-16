# Variables para ambiente de DESARROLLO

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

# DynamoDB
variable "dynamodb_billing_mode" {
  description = "Modo de facturación de DynamoDB: PAY_PER_REQUEST o PROVISIONED"
  type        = string
  default     = "PAY_PER_REQUEST" # On-demand, ideal para desarrollo
}

variable "enable_point_in_time_recovery" {
  description = "Habilitar point-in-time recovery para DynamoDB"
  type        = bool
  default     = false # False para ahorrar costos en desarrollo
}

# Lambda
variable "lambda_memory_size" {
  description = "Memoria para funciones Lambda en MB"
  type        = number
  default     = 256
}

variable "lambda_timeout" {
  description = "Timeout para funciones Lambda en segundos"
  type        = number
  default     = 30
}

variable "enable_xray_tracing" {
  description = "Habilitar AWS X-Ray tracing"
  type        = bool
  default     = false # False para desarrollo, true para producción
}

# API Gateway
variable "api_throttle_rate_limit" {
  description = "Rate limit para API Gateway (requests/segundo)"
  type        = number
  default     = 100
}

variable "api_throttle_burst_limit" {
  description = "Burst limit para API Gateway"
  type        = number
  default     = 50
}

# Monitoreo
variable "create_cloudwatch_alarms" {
  description = "Crear alarmas de CloudWatch"
  type        = bool
  default     = true
}

variable "create_sns_notifications" {
  description = "Crear SNS topic para notificaciones"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email para recibir alarmas (dejar vacío para no configurar)"
  type        = string
  default     = ""
}
