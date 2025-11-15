# Proyecto Individual: Sistema de Tracking de Entregas - DINEX Perú
# Estudiante: [Tu Nombre]
# Curso: Infraestructura como Código
#
# Este proyecto implementa un sistema de tracking en tiempo real
# usando arquitectura serverless en AWS con Terraform

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configuración del provider AWS
# Define la región donde se desplegarán los recursos
provider "aws" {
  region = var.aws_region

  # Tags que se aplicarán a TODOS los recursos automáticamente
  default_tags {
    tags = {
      Project     = "dinex-tracking"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.student_name
      Course      = "InfrastructureAsCode"
      Complexity  = "Individual"
    }
  }
}

# Data source para obtener el ID de la cuenta AWS actual
# Se usa para crear nombres únicos de recursos
data "aws_caller_identity" "current" {}

# ============================================================================
# DYNAMODB TABLE - Base de datos NoSQL para almacenar tracking
# ============================================================================

resource "aws_dynamodb_table" "tracking" {
  # Nombre de la tabla (incluye environment para separar dev/prod)
  name = "${var.project}-tracking-${var.environment}"

  # PAY_PER_REQUEST: Pago por uso, sin necesidad de provisionar capacidad
  # Ventaja: No necesito calcular WCU/RCU, AWS escala automáticamente
  # Ideal para proyecto con tráfico variable
  billing_mode = "PAY_PER_REQUEST"

  # Partition key: Identifica únicamente cada tracking
  hash_key = "tracking_id"

  # Sort key: Permite múltiples registros del mismo tracking ordenados por tiempo
  # Uso: Historial de updates de ubicación
  range_key = "timestamp"

  # Definición de atributos que se usan como keys
  # Solo declaro los que son partition key, sort key o índices
  attribute {
    name = "tracking_id"
    type = "S" # String
  }

  attribute {
    name = "timestamp"
    type = "N" # Number (Unix timestamp)
  }

  attribute {
    name = "package_id"
    type = "S" # String
  }

  # Global Secondary Index: Permite buscar por package_id
  # Ejemplo: "Dame todos los trackings del paquete PKG123"
  # Sin GSI tendría que hacer Scan (lento y costoso)
  global_secondary_index {
    name            = "package-index"
    hash_key        = "package_id"
    projection_type = "ALL" # Incluye todos los atributos en el índice
  }

  # Time To Live: Elimina automáticamente registros antiguos
  # Ahorro de costos: No pago por almacenar datos innecesarios
  # Los registros se eliminan cuando expiry < current_time
  ttl {
    attribute_name = "expiry"
    enabled        = true
  }

  # Habilitar cifrado en reposo (seguridad)
  # Usa KMS de AWS (sin costo adicional)
  server_side_encryption {
    enabled = true
  }

  # Habilitar Point-in-time recovery en producción
  # Permite restaurar la tabla a cualquier punto en los últimos 35 días
  point_in_time_recovery {
    enabled = var.environment == "prod" ? true : false
  }

  tags = {
    Name        = "${var.project}-tracking-table"
    Description = "Tabla de tracking de paquetes en tiempo real"
  }
}

# ============================================================================
# IAM ROLE - Rol para las funciones Lambda
# ============================================================================

resource "aws_iam_role" "lambda_role" {
  name = "${var.project}-lambda-role-${var.environment}"

  # Assume role policy: Define QUIÉN puede asumir este rol
  # En este caso: El servicio Lambda de AWS
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.project}-lambda-role"
    Description = "Rol IAM para funciones Lambda de tracking"
  }
}

# Policy: Define QUÉ puede hacer Lambda con este rol
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  # Policy document con permisos específicos
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Permisos para DynamoDB
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",    # Leer un item específico
          "dynamodb:PutItem",    # Crear/actualizar item
          "dynamodb:Query",      # Buscar items por clave
          "dynamodb:UpdateItem", # Actualizar item parcialmente
          "dynamodb:Scan"        # Escanear tabla (usar con precaución)
        ]
        # Solo en esta tabla específica (principio de menor privilegio)
        Resource = [
          aws_dynamodb_table.tracking.arn,
          "${aws_dynamodb_table.tracking.arn}/index/*" # Incluye GSI
        ]
      },
      # Permisos para CloudWatch Logs
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",  # Crear grupo de logs
          "logs:CreateLogStream", # Crear stream de logs
          "logs:PutLogEvents"     # Escribir logs
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      },
      # Permisos para SNS (notificaciones)
      {
        Effect = "Allow"
        Action = [
          "sns:Publish" # Publicar mensajes en SNS topic
        ]
        Resource = aws_sns_topic.notifications.arn
      }
    ]
  })
}

# ============================================================================
# LAMBDA FUNCTION 1: Tracking
# Maneja consultas (GET) y actualizaciones (POST) de tracking
# ============================================================================

resource "aws_lambda_function" "tracking" {
  # Ubicación del código empaquetado (archivo .zip)
  filename = "${path.module}/../lambda-simple/tracking/deployment.zip"

  # Nombre de la función en AWS
  function_name = "${var.project}-tracking-${var.environment}"

  # Rol IAM que define los permisos de esta función
  role = aws_iam_role.lambda_role.arn

  # Handler: Archivo y función que Lambda ejecutará
  # index.py → función handler()
  handler = "index.handler"

  # Runtime de Python
  runtime = "python3.11"

  # Hash del código fuente: Detecta cambios en el archivo
  # Si cambia el .zip, Lambda actualiza la función automáticamente
  source_code_hash = filebase64sha256("${path.module}/../lambda-simple/tracking/deployment.zip")

  # Timeout: Tiempo máximo de ejecución (segundos)
  # 10 segundos es suficiente para queries a DynamoDB
  timeout = 10

  # Memoria asignada en MB
  # Más memoria = más CPU = más rápido, pero más caro
  # 256 MB es suficiente para este caso
  memory_size = 256

  # Variables de entorno accesibles desde el código Python
  # Se acceden con: os.environ['TABLE_NAME']
  environment {
    variables = {
      TABLE_NAME  = aws_dynamodb_table.tracking.name
      ENVIRONMENT = var.environment
      SNS_TOPIC   = aws_sns_topic.notifications.arn
    }
  }

  # Configuración de logs
  # Los logs se guardan automáticamente en CloudWatch
  logging_config {
    log_format = "JSON" # Formato estructurado para fácil búsqueda
    log_group  = "/aws/lambda/${var.project}-tracking-${var.environment}"
  }

  tags = {
    Name        = "${var.project}-tracking-function"
    Description = "Función Lambda para consultar y actualizar tracking"
  }

  # Dependencias: Asegura que el rol exista antes de crear Lambda
  depends_on = [
    aws_iam_role_policy.lambda_policy,
    aws_cloudwatch_log_group.tracking
  ]
}

# CloudWatch Log Group para la función tracking
# Define retención de logs (ahorro de costos)
resource "aws_cloudwatch_log_group" "tracking" {
  name              = "/aws/lambda/${var.project}-tracking-${var.environment}"
  retention_in_days = var.environment == "prod" ? 30 : 7 # 30 días en prod, 7 en dev

  tags = {
    Name = "${var.project}-tracking-logs"
  }
}

# ============================================================================
# LAMBDA FUNCTION 2: Notifications
# Procesa eventos de DynamoDB Stream y envía notificaciones
# ============================================================================

resource "aws_lambda_function" "notifications" {
  filename         = "${path.module}/../lambda-simple/notifications/deployment.zip"
  function_name    = "${var.project}-notifications-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.11"
  source_code_hash = filebase64sha256("${path.module}/../lambda-simple/notifications/deployment.zip")

  # Menor timeout y memoria porque solo envía notificaciones
  timeout     = 5
  memory_size = 128

  environment {
    variables = {
      TABLE_NAME  = aws_dynamodb_table.tracking.name
      SNS_TOPIC   = aws_sns_topic.notifications.arn
      ENVIRONMENT = var.environment
    }
  }

  logging_config {
    log_format = "JSON"
    log_group  = "/aws/lambda/${var.project}-notifications-${var.environment}"
  }

  tags = {
    Name        = "${var.project}-notifications-function"
    Description = "Función Lambda para enviar notificaciones de tracking"
  }

  depends_on = [
    aws_iam_role_policy.lambda_policy,
    aws_cloudwatch_log_group.notifications
  ]
}

resource "aws_cloudwatch_log_group" "notifications" {
  name              = "/aws/lambda/${var.project}-notifications-${var.environment}"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = {
    Name = "${var.project}-notifications-logs"
  }
}

# ============================================================================
# API GATEWAY HTTP API
# Punto de entrada para los clientes (versión simplificada de REST API)
# ============================================================================

resource "aws_apigatewayv2_api" "api" {
  name          = "${var.project}-api-${var.environment}"
  protocol_type = "HTTP" # HTTP API es más simple y barato que REST API

  # Configuración de CORS: Permite llamadas desde navegadores web
  cors_configuration {
    allow_origins = ["*"] # En producción: especificar dominios permitidos
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization", "X-Api-Key"]
    max_age       = 300 # Caché de preflight requests (segundos)
  }

  tags = {
    Name        = "${var.project}-api"
    Description = "API Gateway para sistema de tracking"
  }
}

# Stage: Ambiente de deployment (dev, prod)
resource "aws_apigatewayv2_stage" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = var.environment
  auto_deploy = true # Deploy automático al actualizar

  # Configuración de logs de acceso
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      error          = "$context.error.message"
    })
  }

  # Throttling: Límite de requests para evitar costos excesivos
  default_route_settings {
    throttling_burst_limit = var.api_throttle_burst # Picos cortos
    throttling_rate_limit  = var.api_throttle_rate  # Sostenido
  }

  tags = {
    Name = "${var.project}-api-stage"
  }

  depends_on = [aws_cloudwatch_log_group.api_gateway]
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project}-${var.environment}"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = {
    Name = "${var.project}-api-gateway-logs"
  }
}

# ============================================================================
# API GATEWAY INTEGRATION - Conecta API Gateway con Lambda
# ============================================================================

resource "aws_apigatewayv2_integration" "tracking" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY" # Proxy: Lambda recibe request completo

  # URI de la función Lambda
  integration_uri = aws_lambda_function.tracking.invoke_arn

  # Método HTTP que API Gateway usa para invocar Lambda (siempre POST)
  integration_method = "POST"

  # Versión del formato de payload
  payload_format_version = "2.0"

  # Timeout: Tiempo máximo de espera (30s máximo)
  timeout_milliseconds = 10000 # 10 segundos
}

# ============================================================================
# API ROUTES - Define los endpoints disponibles
# ============================================================================

# GET /tracking - Consultar estado de un paquete
resource "aws_apigatewayv2_route" "get_tracking" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /tracking"
  target    = "integrations/${aws_apigatewayv2_integration.tracking.id}"
}

# POST /tracking - Actualizar ubicación de un paquete
resource "aws_apigatewayv2_route" "post_tracking" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /tracking"
  target    = "integrations/${aws_apigatewayv2_integration.tracking.id}"
}

# GET /health - Health check (sin autenticación)
resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.tracking.id}"
}

# ============================================================================
# LAMBDA PERMISSION - Permite que API Gateway invoque Lambda
# ============================================================================

resource "aws_lambda_permission" "api_gateway_tracking" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tracking.function_name
  principal     = "apigateway.amazonaws.com"

  # Source ARN: Solo este API puede invocar Lambda (seguridad)
  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# ============================================================================
# SNS TOPIC - Para enviar notificaciones
# ============================================================================

resource "aws_sns_topic" "notifications" {
  name = "${var.project}-notifications-${var.environment}"

  # Configuración de delivery
  display_name = "DINEX Tracking Notifications"

  tags = {
    Name        = "${var.project}-notifications-topic"
    Description = "Topic SNS para notificaciones de tracking"
  }
}

# Suscripción de email (opcional - comentado por defecto)
# Descomentar y agregar email para recibir notificaciones
# resource "aws_sns_topic_subscription" "email" {
#   topic_arn = aws_sns_topic.notifications.arn
#   protocol  = "email"
#   endpoint  = "tu-email@example.com"
# }

# ============================================================================
# CLOUDWATCH DASHBOARD - Monitoreo visual
# ============================================================================

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project}-dashboard-${var.environment}"

  # Definición del dashboard en JSON
  dashboard_body = jsonencode({
    widgets = [
      # Widget 1: Métricas de Lambda
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Invocaciones" }],
            [".", "Errors", { stat = "Sum", label = "Errores" }],
            [".", "Duration", { stat = "Average", label = "Duración Promedio (ms)" }],
            [".", "Throttles", { stat = "Sum", label = "Throttles" }]
          ]
          period = 300 # 5 minutos
          stat   = "Sum"
          region = var.aws_region
          title  = "Lambda - Tracking Function"
          yAxis = {
            left = {
              label = "Count"
            }
          }
        }
      },
      # Widget 2: Métricas de DynamoDB
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", {
              stat       = "Sum"
              label      = "Read Capacity"
              dimensions = { TableName = aws_dynamodb_table.tracking.name }
            }],
            [".", "ConsumedWriteCapacityUnits", {
              stat       = "Sum"
              label      = "Write Capacity"
              dimensions = { TableName = aws_dynamodb_table.tracking.name }
            }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "DynamoDB - Capacidad Consumida"
        }
      },
      # Widget 3: Métricas de API Gateway
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", { stat = "Sum", label = "Total Requests" }],
            [".", "4XXError", { stat = "Sum", label = "4xx Errors" }],
            [".", "5XXError", { stat = "Sum", label = "5xx Errors" }],
            [".", "Latency", { stat = "Average", label = "Latency (ms)" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "API Gateway - Requests y Errores"
        }
      }
    ]
  })
}

# ============================================================================
# CLOUDWATCH ALARMS - Alertas automáticas
# ============================================================================

# Alarma: Errores en Lambda
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project}-lambda-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2                       # 2 periodos consecutivos
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300                     # 5 minutos
  statistic           = "Sum"
  threshold           = var.alarm_error_threshold # Por defecto: 5
  alarm_description   = "Alarma cuando hay más de ${var.alarm_error_threshold} errores en Lambda"
  treat_missing_data  = "notBreaching"          # No alertar si no hay datos

  dimensions = {
    FunctionName = aws_lambda_function.tracking.function_name
  }

  # Acción: Enviar notificación a SNS
  alarm_actions = [aws_sns_topic.notifications.arn]

  tags = {
    Name = "${var.project}-lambda-errors-alarm"
  }
}

# Alarma: Latencia alta en API Gateway
resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "${var.project}-api-latency-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Average"
  threshold           = 2000 # 2 segundos
  alarm_description   = "Alarma cuando la latencia promedio supera 2 segundos"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = aws_apigatewayv2_api.api.id
  }

  alarm_actions = [aws_sns_topic.notifications.arn]

  tags = {
    Name = "${var.project}-api-latency-alarm"
  }
}
