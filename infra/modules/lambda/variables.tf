# Variables para el módulo Lambda

variable "function_name" {
  description = "Nombre de la función Lambda"
  type        = string
}

variable "description" {
  description = "Descripción de la función Lambda"
  type        = string
  default     = ""
}

variable "runtime" {
  description = "Runtime de la función Lambda"
  type        = string
  default     = "python3.11"
}

variable "handler" {
  description = "Handler de la función Lambda (ej: main.handler)"
  type        = string
  default     = "main.handler"
}

variable "filename" {
  description = "Path al archivo ZIP con el código de la función"
  type        = string
  default     = ""
}

variable "source_code_hash" {
  description = "Hash del código fuente para detectar cambios"
  type        = string
  default     = ""
}

variable "memory_size" {
  description = "Memoria asignada a la función Lambda en MB (128-10240)"
  type        = number
  default     = 256

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "memory_size debe estar entre 128 y 10240 MB"
  }
}

variable "timeout" {
  description = "Timeout de la función en segundos (max 900)"
  type        = number
  default     = 30

  validation {
    condition     = var.timeout > 0 && var.timeout <= 900
    error_message = "timeout debe estar entre 1 y 900 segundos"
  }
}

variable "environment_variables" {
  description = "Variables de entorno para la función Lambda"
  type        = map(string)
  default     = {}
}

variable "enable_tracing" {
  description = "Habilitar AWS X-Ray tracing"
  type        = bool
  default     = false
}

variable "reserved_concurrent_executions" {
  description = "Número de ejecuciones concurrentes reservadas (-1 para ilimitado)"
  type        = number
  default     = -1
}

variable "log_retention_days" {
  description = "Días de retención de logs en CloudWatch"
  type        = number
  default     = 7
}

# Permisos
variable "create_custom_policy" {
  description = "Crear política IAM personalizada para la función"
  type        = bool
  default     = false
}

variable "dynamodb_table_arns" {
  description = "Lista de ARNs de tablas DynamoDB a las que la función puede acceder"
  type        = list(string)
  default     = []
}

variable "sqs_queue_arns" {
  description = "Lista de ARNs de colas SQS a las que la función puede acceder"
  type        = list(string)
  default     = []
}

variable "sns_topic_arns" {
  description = "Lista de ARNs de topics SNS a los que la función puede publicar"
  type        = list(string)
  default     = []
}

# Event Sources
variable "sqs_event_source_arn" {
  description = "ARN de la cola SQS para event source mapping"
  type        = string
  default     = ""
}

variable "sqs_batch_size" {
  description = "Tamaño de lote para procesamiento de mensajes SQS"
  type        = number
  default     = 10
}

variable "dynamodb_stream_arn" {
  description = "ARN del stream de DynamoDB para event source mapping"
  type        = string
  default     = ""
}

variable "dynamodb_batch_size" {
  description = "Tamaño de lote para procesamiento de eventos de DynamoDB Streams"
  type        = number
  default     = 100
}

# VPC Configuration (opcional)
variable "vpc_subnet_ids" {
  description = "IDs de subnets de VPC para la función Lambda"
  type        = list(string)
  default     = null
}

variable "vpc_security_group_ids" {
  description = "IDs de security groups para la función Lambda"
  type        = list(string)
  default     = null
}

# Alarmas
variable "create_error_alarm" {
  description = "Crear alarma de CloudWatch para errores"
  type        = bool
  default     = false
}

variable "error_threshold" {
  description = "Número de errores para activar la alarma"
  type        = number
  default     = 5
}

variable "create_throttle_alarm" {
  description = "Crear alarma de CloudWatch para throttling"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags para aplicar a los recursos"
  type        = map(string)
  default     = {}
}
