# Módulo reutilizable para AWS API Gateway REST API
# 100% compatible con AWS Free Tier (1M llamadas/mes)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = var.description

  endpoint_configuration {
    types = [var.endpoint_type]
  }

  tags = var.tags
}

# Deployment de la API
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  # Forzar re-deploy cuando cambian los recursos
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.this.body,
      var.lambda_integrations
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.lambda
  ]
}

# Stage (dev, prod, etc.)
resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.stage_name

  # Variables de stage
  variables = var.stage_variables

  # CloudWatch Logs
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  # X-Ray Tracing
  xray_tracing_enabled = var.xray_tracing_enabled

  tags = var.tags
}

# CloudWatch Log Group para API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.api_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Method Settings (throttling, logging, metrics)
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    # Métricas y logging
    metrics_enabled    = true
    logging_level      = var.logging_level
    data_trace_enabled = var.data_trace_enabled

    # Throttling (Rate Limiting)
    throttling_burst_limit = var.throttle_burst_limit
    throttling_rate_limit  = var.throttle_rate_limit

    # Caching (opcional, tiene costo adicional)
    caching_enabled = var.caching_enabled
  }
}

# Recursos y métodos dinámicos para Lambda
resource "aws_api_gateway_resource" "lambda_resources" {
  for_each = { for idx, integration in var.lambda_integrations : integration.path => integration }

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = each.value.path
}

resource "aws_api_gateway_method" "lambda_methods" {
  for_each = { for idx, integration in var.lambda_integrations : "${integration.path}-${integration.http_method}" => integration }

  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.lambda_resources[each.value.path].id
  http_method   = each.value.http_method
  authorization = var.authorization_type

  # API Key requerida (opcional)
  api_key_required = var.api_key_required
}

resource "aws_api_gateway_integration" "lambda" {
  for_each = { for idx, integration in var.lambda_integrations : "${integration.path}-${integration.http_method}" => integration }

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.lambda_resources[each.value.path].id
  http_method = aws_api_gateway_method.lambda_methods[each.key].http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = each.value.lambda_invoke_arn
}

# Respuestas de método
resource "aws_api_gateway_method_response" "lambda_response_200" {
  for_each = { for idx, integration in var.lambda_integrations : "${integration.path}-${integration.http_method}" => integration }

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.lambda_resources[each.value.path].id
  http_method = aws_api_gateway_method.lambda_methods[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = var.enable_cors
  }
}

# Permisos para que API Gateway invoque Lambda
resource "aws_lambda_permission" "api_gateway" {
  for_each = { for idx, integration in var.lambda_integrations : "${integration.path}-${integration.http_method}" => integration }

  statement_id  = "AllowAPIGatewayInvoke-${each.value.path}-${each.value.http_method}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

# CORS configuration (si está habilitado)
resource "aws_api_gateway_method" "options" {
  for_each = var.enable_cors ? { for idx, integration in var.lambda_integrations : integration.path => integration } : {}

  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.lambda_resources[each.value.path].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  for_each = var.enable_cors ? { for idx, integration in var.lambda_integrations : integration.path => integration } : {}

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.lambda_resources[each.value.path].id
  http_method = aws_api_gateway_method.options[each.key].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options" {
  for_each = var.enable_cors ? { for idx, integration in var.lambda_integrations : integration.path => integration } : {}

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.lambda_resources[each.value.path].id
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options" {
  for_each = var.enable_cors ? { for idx, integration in var.lambda_integrations : integration.path => integration } : {}

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.lambda_resources[each.value.path].id
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = aws_api_gateway_method_response.options[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# API Key (opcional)
resource "aws_api_gateway_api_key" "this" {
  count = var.create_api_key ? 1 : 0

  name    = "${var.api_name}-key"
  enabled = true

  tags = var.tags
}

# Usage Plan
resource "aws_api_gateway_usage_plan" "this" {
  count = var.create_usage_plan ? 1 : 0

  name        = "${var.api_name}-usage-plan"
  description = "Usage plan for ${var.api_name}"

  api_stages {
    api_id = aws_api_gateway_rest_api.this.id
    stage  = aws_api_gateway_stage.this.stage_name
  }

  quota_settings {
    limit  = var.quota_limit
    period = "MONTH"
  }

  throttle_settings {
    burst_limit = var.throttle_burst_limit
    rate_limit  = var.throttle_rate_limit
  }

  tags = var.tags
}

# Asociar API Key con Usage Plan
resource "aws_api_gateway_usage_plan_key" "this" {
  count = var.create_api_key && var.create_usage_plan ? 1 : 0

  key_id        = aws_api_gateway_api_key.this[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.this[0].id
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "api_4xx_errors" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.api_name}-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 20
  alarm_description   = "API Gateway ${var.api_name} tiene muchos errores 4xx"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = aws_api_gateway_rest_api.this.name
    Stage   = aws_api_gateway_stage.this.stage_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "api_5xx_errors" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.api_name}-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "API Gateway ${var.api_name} tiene errores 5xx"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = aws_api_gateway_rest_api.this.name
    Stage   = aws_api_gateway_stage.this.stage_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "api_latency" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.api_name}-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Average"
  threshold           = 2000 # 2 segundos
  alarm_description   = "API Gateway ${var.api_name} tiene alta latencia"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = aws_api_gateway_rest_api.this.name
    Stage   = aws_api_gateway_stage.this.stage_name
  }

  tags = var.tags
}
