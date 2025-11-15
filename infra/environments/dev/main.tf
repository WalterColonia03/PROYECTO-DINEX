# Configuración principal para ambiente de DESARROLLO
# DINEX Perú - Infraestructura Serverless
# 100% FREE TIER COMPATIBLE

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend S3 para estado remoto
  # IMPORTANTE: Ejecutar primero infra/bootstrap para crear el bucket
  backend "s3" {
    bucket         = "dinex-terraform-state-bucket"
    key            = "env/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "dinex-terraform-state-lock"
    encrypt        = true
  }
}

# Provider AWS
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Variables locales
locals {
  project     = "dinex"
  environment = "dev"

  common_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "Terraform"
    Course      = "InfrastructureAsCode"
    University  = "Universidad"
    FreeTier    = "true"
  }
}

# ========================================
# DYNAMODB TABLES
# ========================================

# Tabla de Órdenes
module "orders_table" {
  source = "../../modules/dynamodb"

  table_name   = "${local.project}-${local.environment}-orders"
  billing_mode = var.dynamodb_billing_mode
  hash_key     = "order_id"
  range_key    = "created_at"

  attributes = [
    {
      name = "order_id"
      type = "S"
    },
    {
      name = "created_at"
      type = "S"
    },
    {
      name = "customer_id"
      type = "S"
    },
    {
      name = "status"
      type = "S"
    }
  ]

  # Global Secondary Index para consultas por cliente
  global_secondary_indexes = [
    {
      name            = "customer_index"
      hash_key        = "customer_id"
      range_key       = "created_at"
      projection_type = "ALL"
    },
    {
      name            = "status_index"
      hash_key        = "status"
      range_key       = "created_at"
      projection_type = "ALL"
    }
  ]

  # TTL para eliminar órdenes antiguas automáticamente (30 días)
  ttl_enabled        = true
  ttl_attribute_name = "ttl"

  # Streams para triggers
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  point_in_time_recovery_enabled = var.enable_point_in_time_recovery
  create_alarms                  = var.create_cloudwatch_alarms

  tags = local.common_tags
}

# Tabla de Tracking
module "tracking_table" {
  source = "../../modules/dynamodb"

  table_name   = "${local.project}-${local.environment}-tracking"
  billing_mode = var.dynamodb_billing_mode
  hash_key     = "tracking_id"
  range_key    = "timestamp"

  attributes = [
    {
      name = "tracking_id"
      type = "S"
    },
    {
      name = "timestamp"
      type = "S"
    },
    {
      name = "order_id"
      type = "S"
    }
  ]

  global_secondary_indexes = [
    {
      name            = "order_index"
      hash_key        = "order_id"
      range_key       = "timestamp"
      projection_type = "ALL"
    }
  ]

  stream_enabled   = false
  create_alarms    = var.create_cloudwatch_alarms

  tags = local.common_tags
}

# Tabla de Rutas
module "routes_table" {
  source = "../../modules/dynamodb"

  table_name   = "${local.project}-${local.environment}-routes"
  billing_mode = var.dynamodb_billing_mode
  hash_key     = "route_id"

  attributes = [
    {
      name = "route_id"
      type = "S"
    },
    {
      name = "driver_id"
      type = "S"
    }
  ]

  global_secondary_indexes = [
    {
      name            = "driver_index"
      hash_key        = "driver_id"
      projection_type = "ALL"
    }
  ]

  create_alarms = var.create_cloudwatch_alarms

  tags = local.common_tags
}

# ========================================
# SQS QUEUES
# ========================================

# Cola para procesamiento de órdenes
module "orders_queue" {
  source = "../../modules/sqs"

  queue_name                 = "${local.project}-${local.environment}-orders-queue"
  visibility_timeout_seconds = 300 # 5 minutos
  enable_dlq                 = true
  max_receive_count          = 3
  create_alarms              = var.create_cloudwatch_alarms

  tags = local.common_tags
}

# Cola para notificaciones
module "notifications_queue" {
  source = "../../modules/sqs"

  queue_name                 = "${local.project}-${local.environment}-notifications-queue"
  visibility_timeout_seconds = 60
  enable_dlq                 = true
  create_alarms              = var.create_cloudwatch_alarms

  tags = local.common_tags
}

# ========================================
# LAMBDA FUNCTIONS
# ========================================

# Lambda: Procesar Órdenes
module "lambda_process_orders" {
  source = "../../modules/lambda"

  function_name = "${local.project}-${local.environment}-process-orders"
  description   = "Procesa nuevas órdenes de clientes"

  filename         = "../../../backend/ordenes/function.zip"
  source_code_hash = fileexists("../../../backend/ordenes/function.zip") ? filebase64sha256("../../../backend/ordenes/function.zip") : ""

  runtime     = "python3.11"
  handler     = "main.handler"
  memory_size = var.lambda_memory_size
  timeout     = var.lambda_timeout

  environment_variables = {
    ORDERS_TABLE        = module.orders_table.table_name
    NOTIFICATIONS_QUEUE = module.notifications_queue.queue_url
    ENVIRONMENT         = local.environment
    LOG_LEVEL           = "INFO"
  }

  create_custom_policy = true
  dynamodb_table_arns  = [module.orders_table.table_arn]
  sqs_queue_arns       = [module.notifications_queue.queue_arn]
  sns_topic_arns       = []

  enable_tracing       = var.enable_xray_tracing
  create_error_alarm   = var.create_cloudwatch_alarms
  create_throttle_alarm = var.create_cloudwatch_alarms

  tags = local.common_tags
}

# Lambda: Tracking
module "lambda_update_tracking" {
  source = "../../modules/lambda"

  function_name = "${local.project}-${local.environment}-update-tracking"
  description   = "Actualiza información de tracking de órdenes"

  filename         = "../../../backend/tracking/function.zip"
  source_code_hash = fileexists("../../../backend/tracking/function.zip") ? filebase64sha256("../../../backend/tracking/function.zip") : ""

  runtime     = "python3.11"
  handler     = "handler.handler"
  memory_size = var.lambda_memory_size
  timeout     = var.lambda_timeout

  environment_variables = {
    TRACKING_TABLE = module.tracking_table.table_name
    ORDERS_TABLE   = module.orders_table.table_name
    ENVIRONMENT    = local.environment
  }

  create_custom_policy = true
  dynamodb_table_arns  = [module.tracking_table.table_arn, module.orders_table.table_arn]
  sqs_queue_arns       = []
  sns_topic_arns       = []

  enable_tracing     = var.enable_xray_tracing
  create_error_alarm = var.create_cloudwatch_alarms

  tags = local.common_tags
}

# Lambda: Optimización de Rutas
module "lambda_optimize_routes" {
  source = "../../modules/lambda"

  function_name = "${local.project}-${local.environment}-optimize-routes"
  description   = "Optimiza rutas de entrega usando algoritmos"

  filename         = "../../../backend/rutas/function.zip"
  source_code_hash = fileexists("../../../backend/rutas/function.zip") ? filebase64sha256("../../../backend/rutas/function.zip") : ""

  runtime     = "python3.11"
  handler     = "optimizer.handler"
  memory_size = 512 # Más memoria para cálculos
  timeout     = 60

  environment_variables = {
    ROUTES_TABLE = module.routes_table.table_name
    ORDERS_TABLE = module.orders_table.table_name
    ENVIRONMENT  = local.environment
  }

  create_custom_policy = true
  dynamodb_table_arns  = [module.routes_table.table_arn, module.orders_table.table_arn]
  sqs_queue_arns       = []
  sns_topic_arns       = []

  enable_tracing     = var.enable_xray_tracing
  create_error_alarm = var.create_cloudwatch_alarms

  tags = local.common_tags
}

# Lambda: Notificaciones
module "lambda_send_notifications" {
  source = "../../modules/lambda"

  function_name = "${local.project}-${local.environment}-send-notifications"
  description   = "Envía notificaciones a clientes"

  filename         = "../../../backend/notificaciones/function.zip"
  source_code_hash = fileexists("../../../backend/notificaciones/function.zip") ? filebase64sha256("../../../backend/notificaciones/function.zip") : ""

  runtime     = "python3.11"
  handler     = "notify.handler"
  memory_size = var.lambda_memory_size
  timeout     = var.lambda_timeout

  environment_variables = {
    ENVIRONMENT = local.environment
  }

  # Event source mapping desde SQS
  sqs_event_source_arn = module.notifications_queue.queue_arn
  sqs_batch_size       = 10

  create_custom_policy = true
  dynamodb_table_arns  = []
  sqs_queue_arns       = [module.notifications_queue.queue_arn]
  sns_topic_arns       = []

  enable_tracing     = var.enable_xray_tracing
  create_error_alarm = var.create_cloudwatch_alarms

  tags = local.common_tags
}

# ========================================
# API GATEWAY
# ========================================

module "api_gateway" {
  source = "../../modules/api_gateway"

  api_name    = "${local.project}-${local.environment}-api"
  description = "API REST para DINEX - Operador Logístico"
  stage_name  = local.environment

  lambda_integrations = [
    {
      path                 = "orders"
      http_method          = "POST"
      lambda_function_name = module.lambda_process_orders.function_name
      lambda_invoke_arn    = module.lambda_process_orders.function_invoke_arn
    },
    {
      path                 = "orders"
      http_method          = "GET"
      lambda_function_name = module.lambda_process_orders.function_name
      lambda_invoke_arn    = module.lambda_process_orders.function_invoke_arn
    },
    {
      path                 = "tracking"
      http_method          = "GET"
      lambda_function_name = module.lambda_update_tracking.function_name
      lambda_invoke_arn    = module.lambda_update_tracking.function_invoke_arn
    },
    {
      path                 = "tracking"
      http_method          = "PUT"
      lambda_function_name = module.lambda_update_tracking.function_name
      lambda_invoke_arn    = module.lambda_update_tracking.function_invoke_arn
    },
    {
      path                 = "routes"
      http_method          = "POST"
      lambda_function_name = module.lambda_optimize_routes.function_name
      lambda_invoke_arn    = module.lambda_optimize_routes.function_invoke_arn
    }
  ]

  enable_cors          = true
  throttle_rate_limit  = var.api_throttle_rate_limit
  throttle_burst_limit = var.api_throttle_burst_limit

  logging_level        = "INFO"
  xray_tracing_enabled = var.enable_xray_tracing
  create_alarms        = var.create_cloudwatch_alarms

  tags = local.common_tags
}

# ========================================
# MONITORING
# ========================================

module "monitoring" {
  source = "../../modules/monitoring"

  dashboard_name = "${local.project}-${local.environment}-dashboard"
  project_name   = local.project
  environment    = local.environment
  aws_region     = var.aws_region

  lambda_functions = [
    { name = module.lambda_process_orders.function_name },
    { name = module.lambda_update_tracking.function_name },
    { name = module.lambda_optimize_routes.function_name },
    { name = module.lambda_send_notifications.function_name }
  ]

  dynamodb_tables = [
    { name = module.orders_table.table_name },
    { name = module.tracking_table.table_name },
    { name = module.routes_table.table_name }
  ]

  sqs_queues = [
    { name = module.orders_queue.queue_name },
    { name = module.notifications_queue.queue_name }
  ]

  api_gateway_name = module.api_gateway.api_name

  create_sns_topic = var.create_sns_notifications
  alarm_email      = var.alarm_email

  tags = local.common_tags
}
