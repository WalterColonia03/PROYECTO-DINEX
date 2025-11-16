variable "queue_name" {
  description = "Nombre de la cola SQS"
  type        = string
}

variable "delay_seconds" {
  description = "Tiempo de delay para mensajes (0-900 segundos)"
  type        = number
  default     = 0
}

variable "max_message_size" {
  description = "Tamaño máximo del mensaje en bytes (1024-262144)"
  type        = number
  default     = 262144
}

variable "message_retention_seconds" {
  description = "Tiempo de retención de mensajes en segundos (60-1209600)"
  type        = number
  default     = 345600 # 4 días
}

variable "receive_wait_time_seconds" {
  description = "Tiempo de espera para long polling (0-20 segundos)"
  type        = number
  default     = 20 # Long polling habilitado
}

variable "visibility_timeout_seconds" {
  description = "Timeout de visibilidad (0-43200 segundos)"
  type        = number
  default     = 30
}

variable "enable_dlq" {
  description = "Habilitar Dead Letter Queue"
  type        = bool
  default     = true
}

variable "max_receive_count" {
  description = "Número de recepciones antes de enviar a DLQ"
  type        = number
  default     = 3
}

variable "enable_encryption" {
  description = "Habilitar cifrado con SQS managed keys"
  type        = bool
  default     = true
}

variable "create_alarms" {
  description = "Crear alarmas de CloudWatch"
  type        = bool
  default     = false
}

variable "alarm_message_threshold" {
  description = "Threshold de mensajes para activar alarma"
  type        = number
  default     = 1000
}

variable "tags" {
  description = "Tags para aplicar a los recursos"
  type        = map(string)
  default     = {}
}
