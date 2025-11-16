# Módulo reutilizable para AWS DynamoDB Tables
# 100% compatible con AWS Free Tier (25 GB storage + 25 WCU/RCU)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Tabla DynamoDB
resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = var.billing_mode
  hash_key     = var.hash_key
  range_key    = var.range_key

  # Capacidad (solo si billing_mode = PROVISIONED)
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  # Configuración de TTL (Time To Live)
  dynamic "ttl" {
    for_each = var.ttl_enabled ? [1] : []
    content {
      enabled        = true
      attribute_name = var.ttl_attribute_name
    }
  }

  # Atributos de la tabla
  dynamic "attribute" {
    for_each = var.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  # Global Secondary Indexes (GSI)
  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = lookup(global_secondary_index.value, "range_key", null)
      projection_type = global_secondary_index.value.projection_type
      read_capacity   = var.billing_mode == "PROVISIONED" ? lookup(global_secondary_index.value, "read_capacity", var.read_capacity) : null
      write_capacity  = var.billing_mode == "PROVISIONED" ? lookup(global_secondary_index.value, "write_capacity", var.write_capacity) : null

      dynamic "projection" {
        for_each = lookup(global_secondary_index.value, "non_key_attributes", null) != null ? [1] : []
        content {
          non_key_attributes = global_secondary_index.value.non_key_attributes
        }
      }
    }
  }

  # Local Secondary Indexes (LSI)
  dynamic "local_secondary_index" {
    for_each = var.local_secondary_indexes
    content {
      name            = local_secondary_index.value.name
      range_key       = local_secondary_index.value.range_key
      projection_type = local_secondary_index.value.projection_type

      dynamic "projection" {
        for_each = lookup(local_secondary_index.value, "non_key_attributes", null) != null ? [1] : []
        content {
          non_key_attributes = local_secondary_index.value.non_key_attributes
        }
      }
    }
  }

  # Stream configuration
  stream_enabled   = var.stream_enabled
  stream_view_type = var.stream_enabled ? var.stream_view_type : null

  # Point-in-time recovery (backup automático)
  point_in_time_recovery {
    enabled = var.point_in_time_recovery_enabled
  }

  # Cifrado en reposo
  server_side_encryption {
    enabled     = var.encryption_enabled
    kms_key_arn = var.kms_key_arn
  }

  # Protección contra eliminación
  deletion_protection_enabled = var.deletion_protection_enabled

  tags = merge(
    var.tags,
    {
      Name = var.table_name
    }
  )
}

# Auto Scaling para capacidad de lectura (solo si billing_mode = PROVISIONED)
resource "aws_appautoscaling_target" "read_target" {
  count              = var.billing_mode == "PROVISIONED" && var.autoscaling_enabled ? 1 : 0
  max_capacity       = var.autoscaling_read_max_capacity
  min_capacity       = var.read_capacity
  resource_id        = "table/${aws_dynamodb_table.this.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "read_policy" {
  count              = var.billing_mode == "PROVISIONED" && var.autoscaling_enabled ? 1 : 0
  name               = "${var.table_name}-read-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.read_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.read_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.read_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = var.autoscaling_read_target
  }
}

# Auto Scaling para capacidad de escritura (solo si billing_mode = PROVISIONED)
resource "aws_appautoscaling_target" "write_target" {
  count              = var.billing_mode == "PROVISIONED" && var.autoscaling_enabled ? 1 : 0
  max_capacity       = var.autoscaling_write_max_capacity
  min_capacity       = var.write_capacity
  resource_id        = "table/${aws_dynamodb_table.this.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "write_policy" {
  count              = var.billing_mode == "PROVISIONED" && var.autoscaling_enabled ? 1 : 0
  name               = "${var.table_name}-write-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.write_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.write_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.write_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = var.autoscaling_write_target
  }
}

# CloudWatch Alarms para DynamoDB

# Alarma para Read Throttling
resource "aws_cloudwatch_metric_alarm" "read_throttle_alarm" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.table_name}-read-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReadThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alarma cuando hay throttling de lecturas en ${var.table_name}"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.this.name
  }

  tags = var.tags
}

# Alarma para Write Throttling
resource "aws_cloudwatch_metric_alarm" "write_throttle_alarm" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.table_name}-write-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "WriteThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alarma cuando hay throttling de escrituras en ${var.table_name}"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.this.name
  }

  tags = var.tags
}

# Alarma para User Errors
resource "aws_cloudwatch_metric_alarm" "user_errors_alarm" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.table_name}-user-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alarma cuando hay errores de usuario en ${var.table_name}"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.this.name
  }

  tags = var.tags
}
