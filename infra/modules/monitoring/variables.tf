variable "dashboard_name" {
  description = "Nombre del dashboard de CloudWatch"
  type        = string
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, prod)"
  type        = string
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "lambda_functions" {
  description = "Lista de funciones Lambda a monitorear"
  type = list(object({
    name = string
  }))
  default = []
}

variable "dynamodb_tables" {
  description = "Lista de tablas DynamoDB a monitorear"
  type = list(object({
    name = string
  }))
  default = []
}

variable "sqs_queues" {
  description = "Lista de colas SQS a monitorear"
  type = list(object({
    name = string
  }))
  default = []
}

variable "api_gateway_name" {
  description = "Nombre del API Gateway a monitorear"
  type        = string
  default     = ""
}

variable "create_sns_topic" {
  description = "Crear SNS topic para notificaciones"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email para recibir notificaciones de alarmas"
  type        = string
  default     = ""
}

variable "create_composite_alarm" {
  description = "Crear alarma compuesta"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags para aplicar a los recursos"
  type        = map(string)
  default     = {}
}
