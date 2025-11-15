# DINEX Perú - Infraestructura como Código (IaC)

![AWS](https://img.shields.io/badge/AWS-Free_Tier-orange?logo=amazon-aws)
![Terraform](https://img.shields.io/badge/Terraform-1.6+-623CE4?logo=terraform)
![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python)
![License](https://img.shields.io/badge/License-Academic-green)

## Descripción del Proyecto

**DINEX Perú** es un operador logístico líder en el sector retail y e-commerce que enfrenta desafíos críticos de escalabilidad durante picos de demanda impredecibles (Black Friday, Cyber Monday, campañas navideñas). Este proyecto implementa una **arquitectura serverless completamente gestionada** en AWS utilizando Infraestructura como Código (IaC) para resolver estos desafíos.

### Contexto Empresarial

- **Empresa**: DINEX Perú - Operador Logístico
- **Sector**: Retail, E-commerce, Distribución
- **Problema**:
  - Picos de demanda impredecibles (hasta 50x en Black Friday)
  - Altos costos de infraestructura sobre-provisionada
  - Baja elasticidad en arquitectura tradicional
  - Tiempo de respuesta > 2 segundos en horas pico

### Solución Propuesta

Arquitectura serverless con auto-scaling automático que permite:
- **Escalabilidad infinita**: De 0 a 10,000 solicitudes/segundo
- **Reducción de costos**: 60% menos vs infraestructura tradicional
- **Alta disponibilidad**: 99.9% SLA garantizado
- **Pago por uso**: Solo pagas por lo que usas (Free Tier para desarrollo)

---

## Arquitectura

```
┌─────────────┐
│   Cliente   │
│  (Usuario)  │
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│  API Gateway    │ ← Endpoints REST + Rate Limiting
└────────┬────────┘
         │
    ┌────┴────┬───────────┬───────────┐
    ▼         ▼           ▼           ▼
┌─────────┐ ┌──────────┐ ┌────────┐ ┌──────────┐
│ Lambda  │ │ Lambda   │ │Lambda  │ │ Lambda   │
│ Orders  │ │ Tracking │ │Routes  │ │ Notify   │
└────┬────┘ └─────┬────┘ └───┬────┘ └────┬─────┘
     │            │           │           │
     ▼            ▼           ▼           ▼
┌──────────────────────────────────────────────┐
│            DynamoDB Tables                   │
│  ┌─────────┐ ┌──────────┐ ┌──────────┐     │
│  │ Orders  │ │ Tracking │ │  Routes  │     │
│  └─────────┘ └──────────┘ └──────────┘     │
└──────────────────────────────────────────────┘
         │
         ▼
┌─────────────────┐       ┌──────────────┐
│   SQS Queues    │──────▶│ CloudWatch   │
│ (Async Tasks)   │       │ (Monitoring) │
└─────────────────┘       └──────────────┘
```

---

## Stack Tecnológico

### Infraestructura (100% Free Tier)

| Servicio | Uso | Free Tier |
|----------|-----|-----------|
| **AWS Lambda** | Funciones serverless para lógica de negocio | 1M requests/mes + 400,000 GB-s |
| **DynamoDB** | Base de datos NoSQL | 25 GB storage + 25 WCU/RCU |
| **API Gateway** | API REST pública | 1M llamadas/mes |
| **SQS** | Colas de mensajes asíncronas | 1M requests/mes |
| **CloudWatch** | Logs y monitoreo | 5 GB logs + 10 métricas custom |
| **S3** | Almacenamiento de estado Terraform | 5 GB storage |

### IaC & DevOps

- **Terraform** 1.6+ - Provisión de infraestructura
- **GitHub Actions** - CI/CD pipeline automatizado
- **Ansible** - Configuración post-deployment
- **Checkov** - Análisis de seguridad estático

### Backend

- **Python 3.11** - Runtime de Lambda
- **Boto3** - AWS SDK
- **Pytest** - Testing unitario

---

## Estructura del Proyecto

```
proyecto-dinex-iac/
├── README.md                    # Este archivo
├── Makefile                     # Comandos de automatización
├── .gitignore
│
├── .github/workflows/
│   └── deploy.yml              # Pipeline CI/CD
│
├── infra/
│   ├── bootstrap/              # Setup inicial (S3 backend)
│   │   ├── main.tf
│   │   └── variables.tf
│   │
│   ├── environments/
│   │   ├── dev/                # Ambiente desarrollo
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── terraform.tfvars
│   │   │   └── outputs.tf
│   │   └── prod/               # Ambiente producción
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── terraform.tfvars
│   │       └── outputs.tf
│   │
│   └── modules/                # Módulos reutilizables
│       ├── lambda/
│       ├── dynamodb/
│       ├── api_gateway/
│       ├── sqs/
│       └── monitoring/
│
├── backend/                    # Código Lambda
│   ├── ordenes/
│   │   ├── main.py
│   │   ├── requirements.txt
│   │   └── tests/
│   ├── tracking/
│   ├── rutas/
│   └── notificaciones/
│
├── ansible/
│   ├── playbook.yml
│   └── inventory.ini
│
└── docs/
    ├── ARQUITECTURA.md
    ├── JUSTIFICACION.md
    └── diagrams/
```

---

## Instalación y Configuración

### Prerrequisitos

```bash
# Verificar versiones
terraform --version  # >= 1.6.0
python --version     # >= 3.11
aws --version        # AWS CLI v2
make --version       # GNU Make
```

### 1. Configurar AWS Credentials

```bash
# Configurar credenciales (usar cuenta AWS Educate o Free Tier)
aws configure

# Verificar configuración
aws sts get-caller-identity
```

### 2. Bootstrap - Crear Backend de Terraform

```bash
# Crear bucket S3 para estado remoto
cd infra/bootstrap
terraform init
terraform apply
```

### 3. Desplegar Ambiente de Desarrollo

```bash
# Opción 1: Usando Make (recomendado)
make init ENV=dev
make plan ENV=dev
make apply ENV=dev

# Opción 2: Terraform directo
cd infra/environments/dev
terraform init
terraform plan
terraform apply
```

### 4. Empaquetar y Desplegar Funciones Lambda

```bash
# Empaquetar todas las funciones
make deploy-lambda

# O individualmente
cd backend/ordenes
pip install -r requirements.txt -t .
zip -r function.zip .
```

---

## Comandos Disponibles (Makefile)

```bash
make init ENV=dev          # Inicializar Terraform
make validate ENV=dev      # Validar configuración
make plan ENV=dev          # Ver plan de cambios
make apply ENV=dev         # Aplicar cambios
make destroy ENV=dev       # Destruir infraestructura
make lint                  # Análisis estático (tflint + checkov)
make deploy-lambda         # Empaquetar funciones Lambda
make test                  # Ejecutar tests
make output ENV=dev        # Mostrar outputs
make clean                 # Limpiar archivos temporales
```

---

## Testing

### Tests Unitarios Lambda

```bash
# Ejecutar todos los tests
make test

# Test individual
cd backend/ordenes
pytest tests/ -v
```

### Prueba de API

```bash
# Obtener URL del API Gateway
make output ENV=dev | grep api_url

# Crear orden
curl -X POST https://xxx.execute-api.us-east-1.amazonaws.com/dev/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "CUST001",
    "products": [
      {"sku": "PROD123", "quantity": 2}
    ],
    "delivery_address": "Av. Javier Prado 123, Lima"
  }'

# Consultar tracking
curl https://xxx.execute-api.us-east-1.amazonaws.com/dev/tracking/ORDER123
```

---

## Monitoreo

### CloudWatch Dashboard

Accede al dashboard en AWS Console:
```
CloudWatch → Dashboards → dinex-dev-dashboard
```

Métricas incluidas:
- Latencia de Lambda (p50, p95, p99)
- Errores y throttling
- Capacidad consumida de DynamoDB
- Mensajes en cola SQS
- Costos estimados

### Alarmas Configuradas

- **Lambda Errors** > 5 en 5 minutos → Email
- **API Latency** > 2 segundos → Email
- **DynamoDB Throttling** → Email
- **SQS Messages** > 1000 → Email

---

## CI/CD Pipeline

El proyecto incluye GitHub Actions para CI/CD automático:

### Workflow

```
Push to develop → Validate → Security Scan → Deploy to DEV
Push to main    → Validate → Security Scan → Manual Approval → Deploy to PROD
```

### Configurar Secrets en GitHub

```bash
Settings → Secrets → Actions → New repository secret

AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=us-east-1
```

---

## Métricas de Éxito

### Objetivos del Proyecto

| Métrica | Antes (EC2) | Después (Serverless) | Mejora |
|---------|-------------|----------------------|--------|
| **Costo mensual** | $500 | $200 | -60% |
| **Escalabilidad** | 1,000 req/s | 10,000 req/s | 10x |
| **Tiempo respuesta** | 2.5s | 0.8s | -68% |
| **Disponibilidad** | 99.5% | 99.9% | +0.4% |
| **Time to scale** | 15 min | < 1 min | Instantáneo |

### Costos Estimados (Free Tier)

**Ambiente DEV**: $0 - $20/mes (dentro de Free Tier)
**Ambiente PROD**: $150 - $300/mes (según volumen)

---

## Seguridad

### Mejores Prácticas Implementadas

- ✅ **Least Privilege**: IAM roles con permisos mínimos
- ✅ **Encryption at Rest**: DynamoDB + S3 con KMS
- ✅ **Encryption in Transit**: HTTPS/TLS 1.2+
- ✅ **Secrets Management**: AWS Secrets Manager
- ✅ **Network Isolation**: VPC endpoints (opcional)
- ✅ **Security Scanning**: Checkov en CI/CD
- ✅ **Audit Logging**: CloudTrail habilitado

### Análisis de Seguridad

```bash
# Ejecutar Checkov
make lint

# Revisar recomendaciones
checkov -d infra/ --framework terraform
```

---

## Troubleshooting

### Problemas Comunes

**Error: "Access Denied" al crear recursos**
```bash
# Verificar permisos IAM
aws iam get-user
aws iam list-attached-user-policies --user-name YOUR_USER
```

**Lambda timeout**
```bash
# Aumentar timeout en variables.tf
lambda_timeout = 60  # Aumentar a 60 segundos
```

**DynamoDB throttling**
```bash
# Cambiar a on-demand en terraform.tfvars
dynamodb_billing_mode = "PAY_PER_REQUEST"
```

### Logs

```bash
# Ver logs de Lambda
aws logs tail /aws/lambda/dinex-dev-process-orders --follow

# Ver logs de API Gateway
aws logs tail /aws/apigateway/dinex-dev-api --follow
```

---

## Roadmap

### Fase 1 (Actual)
- ✅ Arquitectura serverless básica
- ✅ CI/CD con GitHub Actions
- ✅ Monitoreo con CloudWatch

### Fase 2 (Futuro)
- ⬜ Integración con Cognito para autenticación
- ⬜ CDN con CloudFront
- ⬜ Multi-región para DR
- ⬜ Machine Learning para optimización de rutas

---

## Contribución

Este es un proyecto académico para el curso de **Infraestructura como Código**. Contribuciones y mejoras son bienvenidas:

1. Fork el proyecto
2. Crea un branch (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -am 'Agregar funcionalidad'`)
4. Push al branch (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request

---

## Licencia

Este proyecto es de uso académico para la Universidad. Desarrollado como parte del curso de Infraestructura como Código.

---

## Autores

- **Proyecto**: DINEX Perú - Arquitectura Serverless
- **Curso**: Infraestructura como Código
- **Institución**: Universidad
- **Año**: 2025

---

## Referencias y Recursos

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)

---

## Soporte

Para preguntas o problemas:
1. Revisar documentación en `/docs`
2. Consultar logs en CloudWatch
3. Abrir issue en GitHub (proyecto académico)

**¡Buena suerte con el proyecto! 🚀**
