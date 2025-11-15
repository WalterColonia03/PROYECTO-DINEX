# Valores para PRODUCCIÓN

aws_region = "us-east-1"

# DynamoDB - Configuración de producción
dynamodb_billing_mode         = "PAY_PER_REQUEST"
enable_point_in_time_recovery = true # Backup automático

# Lambda - Configuración optimizada
lambda_memory_size  = 512
lambda_timeout      = 60
enable_xray_tracing = true # Para debugging y monitoreo

# API Gateway - Mayor capacidad
api_throttle_rate_limit  = 1000
api_throttle_burst_limit = 500

# Monitoring
create_cloudwatch_alarms = true
create_sns_notifications = true
alarm_email              = "ops@dinex.pe" # CAMBIAR por email real
