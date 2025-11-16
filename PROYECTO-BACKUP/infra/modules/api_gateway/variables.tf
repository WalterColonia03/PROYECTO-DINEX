# Variables para el módulo API Gateway

variable "api_name" {
  description = "Nombre de la API Gateway"
  type        = string
}

variable "description" {
  description = "Descripción de la API"
  type        = string
  default     = ""
}

variable "stage_name" {
  description = "Nombre del stage (dev, prod, etc.)"
  type        = string
  default     = "dev"
}

variable "endpoint_type" {
  description = "Tipo de endpoint: REGIONAL, EDGE, PRIVATE"
  type        = string
  default     = "REGIONAL"
}

variable "lambda_integrations" {
  description = "Lista de integraciones Lambda"
  type = list(object({
    path                 = string
    http_method          = string
    lambda_function_name = string
    lambda_invoke_arn    = string
  }))
  default = []
}

variable "authorization_type" {
  description = "Tipo de autorización: NONE, AWS_IAM, CUSTOM, COGNITO_USER_POOLS"
  type        = string
  default     = "NONE"
}

variable "api_key_required" {
  description = "API Key requerida para acceso"
  type        = bool
  default     = false
}

variable "enable_cors" {
  description = "Habilitar CORS"
  type        = bool
  default     = true
}

variable "throttle_burst_limit" {
  description = "Límite de burst para throttling"
  type        = number
  default     = 50
}

variable "throttle_rate_limit" {
  description = "Límite de rate para throttling (requests/segundo)"
  type        = number
  default     = 100
}

variable "logging_level" {
  description = "Nivel de logging: OFF, ERROR, INFO"
  type        = string
  default     = "INFO"
}

variable "data_trace_enabled" {
  description = "Habilitar data tracing"
  type        = bool
  default     = false
}

variable "xray_tracing_enabled" {
  description = "Habilitar X-Ray tracing"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Días de retención de logs"
  type        = number
  default     = 7
}

variable "caching_enabled" {
  description = "Habilitar caché (tiene costo adicional)"
  type        = bool
  default     = false
}

variable "stage_variables" {
  description = "Variables del stage"
  type        = map(string)
  default     = {}
}

variable "create_api_key" {
  description = "Crear API Key"
  type        = bool
  default     = false
}

variable "create_usage_plan" {
  description = "Crear Usage Plan"
  type        = bool
  default     = false
}

variable "quota_limit" {
  description = "Límite de cuota mensual"
  type        = number
  default     = 1000000 # 1M dentro del free tier
}

variable "create_alarms" {
  description = "Crear alarmas de CloudWatch"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags para aplicar a los recursos"
  type        = map(string)
  default     = {}
}
