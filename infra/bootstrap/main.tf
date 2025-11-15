# Bootstrap - Crear S3 bucket para estado remoto de Terraform
# Este archivo debe ejecutarse PRIMERO antes de desplegar la infraestructura principal

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "dinex"
      Environment = "shared"
      ManagedBy   = "Terraform"
      Purpose     = "TerraformStateBackend"
    }
  }
}

# S3 Bucket para almacenar estado de Terraform (100% GRATIS en Free Tier)
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  # Prevenir eliminación accidental
  lifecycle {
    prevent_destroy = false # Cambiar a true en producción
  }

  tags = {
    Name        = "Terraform State Backend"
    Description = "Bucket S3 para estado remoto de Terraform - DINEX IaC"
  }
}

# Habilitar versionado para el bucket (protección contra eliminación accidental)
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Habilitar cifrado en reposo (seguridad)
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # Cifrado gratuito con AES256
    }
  }
}

# Bloquear acceso público al bucket (seguridad)
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Table para lock de estado (GRATIS en Free Tier - 25 GB)
# Previene que múltiples usuarios modifiquen el estado simultáneamente
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST" # On-demand, solo pagas por lo que usas
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # Habilitar point-in-time recovery (opcional, útil para producción)
  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  tags = {
    Name        = "Terraform State Lock"
    Description = "Tabla DynamoDB para lock de estado de Terraform"
  }
}

# Outputs útiles
output "state_bucket_name" {
  description = "Nombre del bucket S3 para estado de Terraform"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB para locks"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "backend_config" {
  description = "Configuración del backend para usar en otros módulos"
  value = <<-EOT
    Configuración del backend S3:

    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.terraform_state.id}"
        key            = "env/<ENVIRONMENT>/terraform.tfstate"
        region         = "${var.aws_region}"
        dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
        encrypt        = true
      }
    }
  EOT
}
