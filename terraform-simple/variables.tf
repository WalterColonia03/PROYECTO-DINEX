# Variables de configuración para el proyecto de tracking
# Estas variables permiten personalizar el deployment sin modificar el código

variable "aws_region" {
  description = "Región de AWS donde se desplegarán los recursos"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^us-|^eu-|^ap-", var.aws_region))
    error_message = "La región debe ser una región válida de AWS (ej: us-east-1, eu-west-1)"
  }
}

variable "environment" {
  description = "Ambiente de deployment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "El ambiente debe ser: dev, staging o prod"
  }
}

variable "project" {
  description = "Nombre del proyecto (se usa como prefijo en recursos)"
  type        = string
  default     = "dinex"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.project))
    error_message = "El nombre del proyecto debe empezar con letra minúscula y contener solo letras, números y guiones"
  }
}

variable "student_name" {
  description = "Nombre del estudiante (para tags y trazabilidad)"
  type        = string
  default     = "Estudiante"
}

# Configuración de API Gateway

variable "api_throttle_rate" {
  description = "Límite de requests por segundo (requests/segundo sostenido)"
  type        = number
  default     = 100

  validation {
    condition     = var.api_throttle_rate >= 1 && var.api_throttle_rate <= 10000
    error_message = "El rate limit debe estar entre 1 y 10000 requests/segundo"
  }
}

variable "api_throttle_burst" {
  description = "Límite de burst (picos cortos de tráfico)"
  type        = number
  default     = 50

  validation {
    condition     = var.api_throttle_burst >= 0 && var.api_throttle_burst <= 5000
    error_message = "El burst limit debe estar entre 0 y 5000"
  }
}

# Configuración de CloudWatch Alarms

variable "alarm_error_threshold" {
  description = "Número de errores que dispara la alarma"
  type        = number
  default     = 5

  validation {
    condition     = var.alarm_error_threshold > 0
    error_message = "El threshold debe ser mayor a 0"
  }
}

# Tags adicionales (opcional)

variable "additional_tags" {
  description = "Tags adicionales para aplicar a todos los recursos"
  type        = map(string)
  default     = {}
}
