# Variables para bootstrap de Terraform

variable "aws_region" {
  description = "Región de AWS donde se crearán los recursos"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Nombre del bucket S3 para el estado de Terraform (debe ser único globalmente)"
  type        = string
  default     = "dinex-terraform-state-bucket"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.state_bucket_name))
    error_message = "El nombre del bucket debe contener solo letras minúsculas, números y guiones"
  }
}

variable "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB para locks de estado"
  type        = string
  default     = "dinex-terraform-state-lock"
}

variable "enable_point_in_time_recovery" {
  description = "Habilitar point-in-time recovery para DynamoDB (recomendado para producción)"
  type        = bool
  default     = false # False para ambiente de desarrollo (gratis)
}
