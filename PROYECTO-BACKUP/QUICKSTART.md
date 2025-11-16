# Guía de Inicio Rápido - DINEX Perú

Esta guía te ayudará a desplegar el proyecto completo en **menos de 30 minutos**.

---

## Prerrequisitos

### 1. Cuenta AWS (Free Tier)

Crea una cuenta AWS gratuita:
- Ve a [aws.amazon.com](https://aws.amazon.com)
- Click en "Create an AWS Account"
- Sigue los pasos (requiere tarjeta de crédito pero no te cobrarán si te mantienes en Free Tier)

### 2. Instalar Herramientas

#### En Windows:

```powershell
# Instalar Chocolatey (gestor de paquetes)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Instalar herramientas
choco install terraform awscli python git make -y
```

#### En macOS:

```bash
# Instalar Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Instalar herramientas
brew install terraform awscli python@3.11 git make
```

#### En Linux (Ubuntu/Debian):

```bash
# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Python y Make
sudo apt install python3.11 python3-pip make git -y
```

### 3. Verificar Instalación

```bash
terraform --version   # Debe mostrar >= 1.6.0
aws --version         # Debe mostrar AWS CLI 2.x
python --version      # Debe mostrar Python 3.11
make --version        # Debe mostrar GNU Make
git --version         # Debe mostrar git
```

---

## Configuración Inicial

### 1. Configurar AWS Credentials

```bash
aws configure
```

Introduce:
- **AWS Access Key ID**: Tu access key (obtenerla en AWS Console → IAM → Users → Security Credentials)
- **AWS Secret Access Key**: Tu secret key
- **Default region**: `us-east-1`
- **Default output format**: `json`

### 2. Clonar el Proyecto (o navegar a la carpeta)

```bash
cd "c:\Users\walte\Downloads\INFRAESTRUCTURA COMO CODIGO CURSO\Backend-main\INFRAESTRUCTURA DINEX"
```

### 3. Verificar Prerrequisitos

```bash
make check
```

Debe mostrar:
```
✓ Terraform instalado
✓ AWS CLI instalado
✓ Python instalado
✓ Make instalado
```

---

## Despliegue en 5 Pasos

### Paso 1: Bootstrap (Crear S3 Backend)

```bash
cd infra/bootstrap
terraform init
terraform apply -auto-approve
```

Esto crea:
- Bucket S3 para estado de Terraform
- Tabla DynamoDB para locks

**Tiempo estimado**: 2 minutos

### Paso 2: Empaquetar Funciones Lambda

```bash
cd ../..  # Volver a la raíz
make deploy-lambda
```

Esto empaqueta todas las funciones Lambda con sus dependencias.

**Tiempo estimado**: 3 minutos

### Paso 3: Inicializar Terraform (DEV)

```bash
make init ENV=dev
```

**Tiempo estimado**: 1 minuto

### Paso 4: Revisar Plan de Terraform

```bash
make plan ENV=dev
```

Revisa los recursos que se crearán:
- 4 funciones Lambda
- 3 tablas DynamoDB
- 2 colas SQS
- 1 API Gateway
- CloudWatch Dashboard y alarmas

**Tiempo estimado**: 1 minuto

### Paso 5: Aplicar Infraestructura

```bash
make apply ENV=dev
```

Escribe `y` cuando pregunte si deseas aplicar.

**Tiempo estimado**: 5-10 minutos

---

## Verificación

### 1. Obtener URL del API

```bash
make output ENV=dev
```

Busca `api_gateway_url`. Ejemplo:
```
api_gateway_url = "https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev"
```

### 2. Probar el API

#### Crear una orden:

```bash
curl -X POST https://TU_API_URL/dev/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "CUST001",
    "products": [
      {
        "sku": "PROD123",
        "quantity": 2,
        "price": 50.00
      }
    ],
    "delivery_address": "Av. Javier Prado 123, Lima"
  }'
```

Respuesta esperada:
```json
{
  "message": "Orden creada exitosamente",
  "order_id": "ORD-XXXX",
  "status": "PENDING",
  "total": 100.0
}
```

#### Listar órdenes:

```bash
curl https://TU_API_URL/dev/orders
```

### 3. Ver Dashboard de CloudWatch

```bash
# Obtener nombre del dashboard
make output ENV=dev | grep dashboard

# O abrir directamente en el navegador:
# https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=dinex-dev-dashboard
```

### 4. Ver Logs

```bash
make logs ENV=dev
```

O manualmente:
```bash
aws logs tail /aws/lambda/dinex-dev-process-orders --follow
```

---

## Estructura del Proyecto

```
INFRAESTRUCTURA DINEX/
├── README.md                    ← Documentación principal
├── QUICKSTART.md                ← Esta guía
├── Makefile                     ← Comandos automatizados
│
├── infra/                       ← Infraestructura como Código
│   ├── bootstrap/               ← Setup inicial (S3 backend)
│   ├── modules/                 ← Módulos reutilizables Terraform
│   │   ├── lambda/
│   │   ├── dynamodb/
│   │   ├── api_gateway/
│   │   ├── sqs/
│   │   └── monitoring/
│   └── environments/            ← Configuración por ambiente
│       ├── dev/
│       └── prod/
│
├── backend/                     ← Código de funciones Lambda
│   ├── ordenes/                 ← Procesar órdenes
│   ├── tracking/                ← Actualizar tracking
│   ├── rutas/                   ← Optimizar rutas
│   └── notificaciones/          ← Enviar notificaciones
│
├── .github/workflows/           ← CI/CD con GitHub Actions
│   └── deploy.yml
│
├── ansible/                     ← Automatización post-deploy
│   ├── playbook.yml
│   └── inventory.ini
│
└── docs/                        ← Documentación técnica
    ├── ARQUITECTURA.md
    └── JUSTIFICACION.md
```

---

## Comandos Útiles

### Desarrollo

```bash
# Formatear código Terraform
make format

# Validar configuración
make validate ENV=dev

# Ver plan de cambios
make plan ENV=dev

# Aplicar cambios
make apply ENV=dev

# Ver outputs
make output ENV=dev
```

### Testing

```bash
# Ejecutar tests unitarios
make test

# Probar API
curl https://TU_API_URL/dev/orders
```

### Monitoreo

```bash
# Ver logs en tiempo real
make logs ENV=dev

# Ver estado de infraestructura
make status ENV=dev
```

### Limpieza

```bash
# Limpiar archivos temporales
make clean

# DESTRUIR infraestructura (¡CUIDADO!)
make destroy ENV=dev
```

---

## Troubleshooting

### Error: "No valid credential sources found"

**Problema**: AWS credentials no configuradas

**Solución**:
```bash
aws configure
# Introduce tus credenciales
```

### Error: "Bucket already exists"

**Problema**: El bucket S3 ya existe (nombres deben ser únicos globalmente)

**Solución**:
Edita `infra/bootstrap/variables.tf` y cambia:
```hcl
variable "state_bucket_name" {
  default = "dinex-terraform-state-bucket-TU-NOMBRE"  # Cambia esto
}
```

### Error: "Lambda function not found"

**Problema**: Funciones Lambda no empaquetadas

**Solución**:
```bash
make deploy-lambda
make apply ENV=dev
```

### Error: "AccessDenied" al crear recursos

**Problema**: Usuario IAM sin permisos suficientes

**Solución**:
Tu usuario IAM necesita estos permisos:
- AmazonS3FullAccess
- AWSLambda_FullAccess
- AmazonDynamoDBFullAccess
- AmazonAPIGatewayAdministrator
- AmazonSQSFullAccess
- CloudWatchFullAccess

### Cold Start Lento

**Problema**: Primera invocación de Lambda tarda > 1 segundo

**Solución**:
Esto es normal (cold start). La segunda invocación será < 100ms.

Para evitarlo:
```hcl
# En infra/modules/lambda/variables.tf
reserved_concurrent_executions = 1  # Mantener 1 instancia warm
```

---

## Costos Estimados

### Ambiente DEV (uso normal)

| Servicio | Costo Mensual |
|----------|---------------|
| Lambda | $0 (Free Tier) |
| DynamoDB | $0 (Free Tier) |
| API Gateway | $3.50 |
| SQS | $0 (Free Tier) |
| CloudWatch | $5 |
| S3 | $0 (Free Tier) |
| **TOTAL** | **$8.50/mes** |

### Ambiente PROD (10,000 req/día)

| Servicio | Costo Mensual |
|----------|---------------|
| Lambda | $20 |
| DynamoDB | $100 |
| API Gateway | $10 |
| SQS | $5 |
| CloudWatch | $20 |
| S3 | $1 |
| **TOTAL** | **$156/mes** |

**IMPORTANTE**: Configura AWS Budgets para recibir alertas si excedes $20/mes

```bash
aws budgets create-budget --cli-input-json file://budget.json
```

---

## Próximos Pasos

### 1. Configurar CI/CD

Sube el proyecto a GitHub y configura secrets:

```bash
# En GitHub: Settings → Secrets → Actions → New repository secret
AWS_ACCESS_KEY_ID=tu_key
AWS_SECRET_ACCESS_KEY=tu_secret
AWS_REGION=us-east-1
```

### 2. Personalizar

- Edita `infra/environments/dev/terraform.tfvars`
- Cambia `alarm_email` a tu email
- Ajusta límites de throttling según necesites

### 3. Deploy a Producción

```bash
make init ENV=prod
make plan ENV=prod
make apply ENV=prod
```

### 4. Agregar Features

Ejemplos de features a agregar:
- Autenticación con Cognito
- Webhooks para eventos
- Integración con servicios externos
- Machine Learning para predicción de demanda

---

## Recursos Adicionales

### Documentación
- [README.md](README.md) - Documentación principal
- [ARQUITECTURA.md](docs/ARQUITECTURA.md) - Detalles técnicos
- [JUSTIFICACION.md](docs/JUSTIFICACION.md) - Análisis costo-beneficio

### Links Útiles
- [AWS Free Tier](https://aws.amazon.com/free/)
- [Terraform Docs](https://www.terraform.io/docs)
- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)

### Soporte

¿Problemas? Revisa:
1. Los logs de CloudWatch
2. El estado de Terraform: `terraform show`
3. La documentación en `/docs`

---

## Checklist de Éxito

- [ ] AWS cuenta creada y configurada
- [ ] Herramientas instaladas (terraform, aws-cli, python)
- [ ] Bootstrap ejecutado exitosamente
- [ ] Funciones Lambda empaquetadas
- [ ] Infraestructura desplegada en DEV
- [ ] API funcionando (probado con curl)
- [ ] Dashboard de CloudWatch accesible
- [ ] Costos bajo control (< $20/mes)

---

**¡Felicitaciones! 🎉**

Has desplegado exitosamente una arquitectura serverless completa en AWS.

**Siguiente paso**: Revisa [ARQUITECTURA.md](docs/ARQUITECTURA.md) para entender cómo funciona todo.
