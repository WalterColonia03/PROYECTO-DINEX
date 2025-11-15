# Variables para el módulo DynamoDB

variable "table_name" {
  description = "Nombre de la tabla DynamoDB"
  type        = string
}

variable "billing_mode" {
  description = "Modo de facturación: PAY_PER_REQUEST (on-demand) o PROVISIONED"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "billing_mode debe ser PAY_PER_REQUEST o PROVISIONED"
  }
}

variable "hash_key" {
  description = "Partition key de la tabla"
  type        = string
}

variable "range_key" {
  description = "Sort key de la tabla (opcional)"
  type        = string
  default     = null
}

variable "attributes" {
  description = "Lista de atributos de la tabla"
  type = list(object({
    name = string
    type = string # S (string), N (number), B (binary)
  }))
}

# Capacidad (solo para PROVISIONED)
variable "read_capacity" {
  description = "Capacidad de lectura provisionada (RCU)"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "Capacidad de escritura provisionada (WCU)"
  type        = number
  default     = 5
}

# Global Secondary Indexes
variable "global_secondary_indexes" {
  description = "Lista de Global Secondary Indexes"
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = optional(string)
    projection_type    = string # ALL, KEYS_ONLY, INCLUDE
    non_key_attributes = optional(list(string))
    read_capacity      = optional(number)
    write_capacity     = optional(number)
  }))
  default = []
}

# Local Secondary Indexes
variable "local_secondary_indexes" {
  description = "Lista de Local Secondary Indexes"
  type = list(object({
    name               = string
    range_key          = string
    projection_type    = string # ALL, KEYS_ONLY, INCLUDE
    non_key_attributes = optional(list(string))
  }))
  default = []
}

# TTL (Time To Live)
variable "ttl_enabled" {
  description = "Habilitar TTL para expiración automática de items"
  type        = bool
  default     = false
}

variable "ttl_attribute_name" {
  description = "Nombre del atributo para TTL"
  type        = string
  default     = "ttl"
}

# Streams
variable "stream_enabled" {
  description = "Habilitar DynamoDB Streams"
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = "Tipo de vista del stream: KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES"
  type        = string
  default     = "NEW_AND_OLD_IMAGES"
}

# Point-in-time Recovery
variable "point_in_time_recovery_enabled" {
  description = "Habilitar point-in-time recovery (backup automático)"
  type        = bool
  default     = false
}

# Cifrado
variable "encryption_enabled" {
  description = "Habilitar cifrado en reposo"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN de la clave KMS para cifrado (null para usar AWS managed key)"
  type        = string
  default     = null
}

# Protección
variable "deletion_protection_enabled" {
  description = "Habilitar protección contra eliminación"
  type        = bool
  default     = false
}

# Auto Scaling
variable "autoscaling_enabled" {
  description = "Habilitar auto-scaling (solo para PROVISIONED)"
  type        = bool
  default     = false
}

variable "autoscaling_read_max_capacity" {
  description = "Capacidad máxima de lectura para auto-scaling"
  type        = number
  default     = 100
}

variable "autoscaling_write_max_capacity" {
  description = "Capacidad máxima de escritura para auto-scaling"
  type        = number
  default     = 100
}

variable "autoscaling_read_target" {
  description = "Target de utilización para auto-scaling de lectura (%)"
  type        = number
  default     = 70
}

variable "autoscaling_write_target" {
  description = "Target de utilización para auto-scaling de escritura (%)"
  type        = number
  default     = 70
}

# Alarmas
variable "create_alarms" {
  description = "Crear alarmas de CloudWatch para la tabla"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags para aplicar a los recursos"
  type        = map(string)
  default     = {}
}
