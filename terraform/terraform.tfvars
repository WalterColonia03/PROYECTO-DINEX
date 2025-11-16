# Valores de variables para el ambiente de DESARROLLO
# Este archivo contiene la configuración específica para dev

# Región de AWS
aws_region = "us-east-1"

# Ambiente (dev, staging, prod)
environment = "dev"

# Nombre del proyecto
project = "dinex"

# Tu nombre (cambiar por tu nombre real)
student_name = "Tu Nombre Aquí"

# Límites de API Gateway (configuración moderada para dev)
api_throttle_rate  = 100 # 100 requests por segundo
api_throttle_burst = 50  # Burst de 50 requests

# Threshold de alarmas
alarm_error_threshold = 5 # Alarma después de 5 errores

# Tags adicionales (opcional)
additional_tags = {
  Universidad = "Tu Universidad"
  Curso       = "Infraestructura como Código"
  Semestre    = "2025-1"
}
