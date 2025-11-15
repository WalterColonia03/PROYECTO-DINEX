# Módulo de Monitoring con CloudWatch Dashboard y Alarmas
# 100% compatible con AWS Free Tier (5 GB logs + 10 métricas custom)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = var.dashboard_name

  dashboard_body = jsonencode({
    widgets = concat(
      # Lambda Metrics
      [
        {
          type = "metric"
          properties = {
            metrics = [
              for lambda in var.lambda_functions : [
                "AWS/Lambda", "Invocations", { stat = "Sum", label = "${lambda.name} Invocations" },
                { dimensions = { FunctionName = lambda.name } }
              ]
            ]
            period = 300
            stat   = "Sum"
            region = var.aws_region
            title  = "Lambda Invocations"
          }
        },
        {
          type = "metric"
          properties = {
            metrics = [
              for lambda in var.lambda_functions : [
                "AWS/Lambda", "Errors", { stat = "Sum", label = "${lambda.name} Errors" },
                { dimensions = { FunctionName = lambda.name } }
              ]
            ]
            period = 300
            stat   = "Sum"
            region = var.aws_region
            title  = "Lambda Errors"
          }
        },
        {
          type = "metric"
          properties = {
            metrics = [
              for lambda in var.lambda_functions : [
                "AWS/Lambda", "Duration", { stat = "Average", label = "${lambda.name} Duration" },
                { dimensions = { FunctionName = lambda.name } }
              ]
            ]
            period = 300
            stat   = "Average"
            region = var.aws_region
            title  = "Lambda Duration (ms)"
          }
        }
      ],
      # DynamoDB Metrics
      length(var.dynamodb_tables) > 0 ? [
        {
          type = "metric"
          properties = {
            metrics = [
              for table in var.dynamodb_tables : [
                "AWS/DynamoDB", "ConsumedReadCapacityUnits", { stat = "Sum", label = "${table.name} Read" },
                { dimensions = { TableName = table.name } }
              ]
            ]
            period = 300
            stat   = "Sum"
            region = var.aws_region
            title  = "DynamoDB Read Capacity"
          }
        },
        {
          type = "metric"
          properties = {
            metrics = [
              for table in var.dynamodb_tables : [
                "AWS/DynamoDB", "ConsumedWriteCapacityUnits", { stat = "Sum", label = "${table.name} Write" },
                { dimensions = { TableName = table.name } }
              ]
            ]
            period = 300
            stat   = "Sum"
            region = var.aws_region
            title  = "DynamoDB Write Capacity"
          }
        }
      ] : [],
      # SQS Metrics
      length(var.sqs_queues) > 0 ? [
        {
          type = "metric"
          properties = {
            metrics = [
              for queue in var.sqs_queues : [
                "AWS/SQS", "ApproximateNumberOfMessagesVisible", { stat = "Average", label = queue.name },
                { dimensions = { QueueName = queue.name } }
              ]
            ]
            period = 300
            stat   = "Average"
            region = var.aws_region
            title  = "SQS Messages in Queue"
          }
        }
      ] : [],
      # API Gateway Metrics
      var.api_gateway_name != "" ? [
        {
          type = "metric"
          properties = {
            metrics = [
              ["AWS/ApiGateway", "Count", { stat = "Sum", label = "Requests" }],
              [".", "4XXError", { stat = "Sum", label = "4xx Errors" }],
              [".", "5XXError", { stat = "Sum", label = "5xx Errors" }]
            ]
            period = 300
            stat   = "Sum"
            region = var.aws_region
            title  = "API Gateway Requests"
            dimensions = {
              ApiName = var.api_gateway_name
            }
          }
        },
        {
          type = "metric"
          properties = {
            metrics = [
              ["AWS/ApiGateway", "Latency", { stat = "Average", label = "Average" }],
              ["...", { stat = "p99", label = "p99" }]
            ]
            period = 300
            region = var.aws_region
            title  = "API Gateway Latency"
            dimensions = {
              ApiName = var.api_gateway_name
            }
          }
        }
      ] : []
    )
  })
}

# SNS Topic para notificaciones de alarmas (GRATIS)
resource "aws_sns_topic" "alarms" {
  count = var.create_sns_topic ? 1 : 0
  name  = "${var.project_name}-${var.environment}-alarms"

  tags = var.tags
}

# Suscripción de email al topic
resource "aws_sns_topic_subscription" "alarm_email" {
  count     = var.create_sns_topic && var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# CloudWatch Log Metric Filter para errores customizados
resource "aws_cloudwatch_log_metric_filter" "error_count" {
  for_each = { for lambda in var.lambda_functions : lambda.name => lambda }

  name           = "${each.value.name}-error-count"
  log_group_name = "/aws/lambda/${each.value.name}"
  pattern        = "[ERROR]"

  metric_transformation {
    name      = "${each.value.name}ErrorCount"
    namespace = "${var.project_name}/${var.environment}"
    value     = "1"
  }
}

# Alarma compuesta para salud general del sistema
resource "aws_cloudwatch_composite_alarm" "system_health" {
  count             = var.create_composite_alarm ? 1 : 0
  alarm_name        = "${var.project_name}-${var.environment}-system-health"
  alarm_description = "Alarma compuesta para salud general del sistema"

  alarm_actions = var.create_sns_topic ? [aws_sns_topic.alarms[0].arn] : []

  alarm_rule = "ALARM(${var.lambda_functions[0].name}-errors) OR ALARM(${var.api_gateway_name}-5xx-errors)"

  tags = var.tags
}
