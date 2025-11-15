# Valores de variables para ambiente de DESARROLLO
# IMPORTANTE: Este archivo contiene la configuración para FREE TIER

aws_region = "us-east-1"

# DynamoDB - Configuración FREE TIER
dynamodb_billing_mode          = "PAY_PER_REQUEST" # Solo pagas por lo que usas
enable_point_in_time_recovery  = false              # Ahorro de costos en dev

# Lambda - Configuración dentro de FREE TIER
lambda_memory_size = 256  # MB
lambda_timeout     = 30   # segundos
enable_xray_tracing = false # Ahorro de costos en dev

# API Gateway - Configuración FREE TIER (1M llamadas/mes)
api_throttle_rate_limit  = 100 # requests/segundo
api_throttle_burst_limit = 50  # burst máximo

# Monitoring y Alarmas
create_cloudwatch_alarms  = true
create_sns_notifications  = true
alarm_email               = "" # CAMBIAR por tu email para recibir alarmas

# NOTAS:
# 1. Para producción, cambiar dynamodb_billing_mode a PROVISIONED con auto-scaling
# 2. Habilitar enable_xray_tracing en producción para debugging
# 3. Configurar alarm_email para recibir notificaciones
# 4. Este archivo NO debe contener información sensible (passwords, keys, etc.)
