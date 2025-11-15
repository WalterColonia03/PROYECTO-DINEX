# Módulo reutilizable para AWS Lambda Functions
# 100% compatible con AWS Free Tier (1M requests/mes + 400,000 GB-s)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# IAM Role para la función Lambda
resource "aws_iam_role" "lambda" {
  name               = "${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.function_name}-role"
    }
  )
}

# Policy document para que Lambda pueda asumir el rol
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Adjuntar política básica de ejecución de Lambda (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Política personalizada para acceso a DynamoDB, SQS, SNS
resource "aws_iam_role_policy" "lambda_custom_policy" {
  count  = var.create_custom_policy ? 1 : 0
  name   = "${var.function_name}-custom-policy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_custom[0].json
}

data "aws_iam_policy_document" "lambda_custom" {
  count = var.create_custom_policy ? 1 : 0

  # Permisos para DynamoDB
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem"
    ]
    resources = var.dynamodb_table_arns
  }

  # Permisos para SQS
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = var.sqs_queue_arns
  }

  # Permisos para SNS (notificaciones)
  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = var.sns_topic_arns
  }

  # Permisos para X-Ray (tracing)
  dynamic "statement" {
    for_each = var.enable_tracing ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords"
      ]
      resources = ["*"]
    }
  }
}

# CloudWatch Log Group para la función Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Función Lambda
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = var.description
  role          = aws_iam_role.lambda.arn

  # Código de la función
  filename         = var.filename
  source_code_hash = var.source_code_hash != "" ? var.source_code_hash : (var.filename != "" ? filebase64sha256(var.filename) : null)

  # Runtime y handler
  runtime = var.runtime
  handler = var.handler

  # Configuración de recursos
  memory_size = var.memory_size
  timeout     = var.timeout

  # Variables de entorno
  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  # Tracing con X-Ray (opcional)
  tracing_config {
    mode = var.enable_tracing ? "Active" : "PassThrough"
  }

  # VPC config (opcional, para acceso a recursos privados)
  dynamic "vpc_config" {
    for_each = var.vpc_subnet_ids != null && var.vpc_security_group_ids != null ? [1] : []
    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  # Reserved concurrent executions (para evitar costos excesivos)
  reserved_concurrent_executions = var.reserved_concurrent_executions

  tags = merge(
    var.tags,
    {
      Name = var.function_name
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_cloudwatch_log_group.lambda
  ]
}

# Event Source Mapping para SQS (si se especifica)
resource "aws_lambda_event_source_mapping" "sqs" {
  count            = var.sqs_event_source_arn != "" ? 1 : 0
  event_source_arn = var.sqs_event_source_arn
  function_name    = aws_lambda_function.this.arn
  batch_size       = var.sqs_batch_size
  enabled          = true

  # Configuración de reintentos
  function_response_types = ["ReportBatchItemFailures"]
}

# Event Source Mapping para DynamoDB Streams (si se especifica)
resource "aws_lambda_event_source_mapping" "dynamodb" {
  count            = var.dynamodb_stream_arn != "" ? 1 : 0
  event_source_arn = var.dynamodb_stream_arn
  function_name    = aws_lambda_function.this.arn
  starting_position = "LATEST"
  batch_size       = var.dynamodb_batch_size
  enabled          = true
}

# CloudWatch Alarm para errores
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count               = var.create_error_alarm ? 1 : 0
  alarm_name          = "${var.function_name}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = var.error_threshold
  alarm_description   = "Lambda function ${var.function_name} has high error rate"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }

  tags = var.tags
}

# CloudWatch Alarm para throttling
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  count               = var.create_throttle_alarm ? 1 : 0
  alarm_name          = "${var.function_name}-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Lambda function ${var.function_name} is being throttled"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }

  tags = var.tags
}
