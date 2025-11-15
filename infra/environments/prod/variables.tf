# Variables para ambiente de PRODUCCIÓN

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "dynamodb_billing_mode" {
  description = "Modo de facturación de DynamoDB"
  type        = string
  default     = "PAY_PER_REQUEST" # Cambiar a PROVISIONED si hay tráfico predecible
}

variable "enable_point_in_time_recovery" {
  description = "Habilitar point-in-time recovery"
  type        = bool
  default     = true # IMPORTANTE en producción
}

variable "lambda_memory_size" {
  description = "Memoria para Lambda"
  type        = number
  default     = 512 # Más memoria en producción
}

variable "lambda_timeout" {
  description = "Timeout para Lambda"
  type        = number
  default     = 60
}

variable "enable_xray_tracing" {
  description = "Habilitar X-Ray tracing"
  type        = bool
  default     = true # IMPORTANTE para debugging en producción
}

variable "api_throttle_rate_limit" {
  description = "Rate limit para API Gateway"
  type        = number
  default     = 1000 # Mayor capacidad en producción
}

variable "api_throttle_burst_limit" {
  description = "Burst limit para API Gateway"
  type        = number
  default     = 500
}

variable "create_cloudwatch_alarms" {
  description = "Crear alarmas de CloudWatch"
  type        = bool
  default     = true
}

variable "create_sns_notifications" {
  description = "Crear SNS notifications"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email para alarmas"
  type        = string
  default     = "ops@dinex.pe"
}
