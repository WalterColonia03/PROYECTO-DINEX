# Módulo reutilizable para AWS SQS (Simple Queue Service)
# 100% compatible con AWS Free Tier (1M requests/mes)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Cola SQS
resource "aws_sqs_queue" "this" {
  name                      = var.queue_name
  delay_seconds             = var.delay_seconds
  max_message_size          = var.max_message_size
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = var.receive_wait_time_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds

  # Dead Letter Queue configuration
  redrive_policy = var.enable_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null

  # Cifrado en reposo
  sqs_managed_sse_enabled = var.enable_encryption

  tags = merge(
    var.tags,
    {
      Name = var.queue_name
    }
  )
}

# Dead Letter Queue (DLQ)
resource "aws_sqs_queue" "dlq" {
  count = var.enable_dlq ? 1 : 0

  name                      = "${var.queue_name}-dlq"
  message_retention_seconds = 1209600 # 14 días

  sqs_managed_sse_enabled = var.enable_encryption

  tags = merge(
    var.tags,
    {
      Name = "${var.queue_name}-dlq"
    }
  )
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "messages_in_queue" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.queue_name}-messages-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = var.alarm_message_threshold
  alarm_description   = "Cola ${var.queue_name} tiene muchos mensajes pendientes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.this.name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "age_of_oldest_message" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.queue_name}-message-age-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 600 # 10 minutos
  alarm_description   = "Mensajes en ${var.queue_name} están esperando mucho tiempo"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.this.name
  }

  tags = var.tags
}

# Alarma para DLQ
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  count               = var.enable_dlq && var.create_alarms ? 1 : 0
  alarm_name          = "${var.queue_name}-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Hay mensajes en la Dead Letter Queue de ${var.queue_name}"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq[0].name
  }

  tags = var.tags
}
