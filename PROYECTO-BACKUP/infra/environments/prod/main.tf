# Configuración principal para ambiente de PRODUCCIÓN
# Similar a DEV pero con configuraciones optimizadas para producción

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "dinex-terraform-state-bucket"
    key            = "env/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "dinex-terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  project     = "dinex"
  environment = "prod"

  common_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "Terraform"
    Course      = "InfrastructureAsCode"
    Critical    = "true"
  }
}

# NOTA: La estructura es idéntica a DEV pero con variables diferentes
# Revisar dev/main.tf para la estructura completa
# En producción se recomienda:
# - DynamoDB con PROVISIONED mode y auto-scaling
# - X-Ray tracing habilitado
# - Point-in-time recovery habilitado
# - Alarmas más estrictas
# - Retention de logs más largo
