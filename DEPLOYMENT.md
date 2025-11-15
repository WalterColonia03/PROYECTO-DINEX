# Guía de Deployment - DINEX Perú

## Resumen de Archivos Creados

Este proyecto contiene **más de 35 archivos** organizados en una arquitectura completa de Infraestructura como Código.

### Estructura Completa

```
INFRAESTRUCTURA DINEX/
│
├── 📄 README.md                          ← Documentación principal
├── 📄 QUICKSTART.md                      ← Guía de inicio rápido (30 min)
├── 📄 DEPLOYMENT.md                      ← Este archivo
├── 📄 Makefile                           ← Automatización de comandos
├── 📄 .gitignore                         ← Archivos a ignorar en Git
│
├── 📁 .github/workflows/
│   └── 📄 deploy.yml                     ← CI/CD con GitHub Actions
│
├── 📁 infra/                             ← Infraestructura como Código
│   │
│   ├── 📁 bootstrap/                     ← Setup inicial (ejecutar primero)
│   │   ├── 📄 main.tf                    ← Crear S3 bucket para estado
│   │   └── 📄 variables.tf               ← Variables del bootstrap
│   │
│   ├── 📁 modules/                       ← Módulos reutilizables de Terraform
│   │   │
│   │   ├── 📁 lambda/                    ← Módulo para AWS Lambda
│   │   │   ├── 📄 main.tf                ← Función Lambda + IAM + Logs
│   │   │   ├── 📄 variables.tf           ← Configuración Lambda
│   │   │   └── 📄 outputs.tf             ← ARNs y nombres
│   │   │
│   │   ├── 📁 dynamodb/                  ← Módulo para DynamoDB
│   │   │   ├── 📄 main.tf                ← Tablas + GSI + Auto-scaling
│   │   │   ├── 📄 variables.tf           ← Configuración tablas
│   │   │   └── 📄 outputs.tf             ← ARNs de tablas
│   │   │
│   │   ├── 📁 api_gateway/               ← Módulo para API Gateway
│   │   │   ├── 📄 main.tf                ← REST API + Endpoints + CORS
│   │   │   ├── 📄 variables.tf           ← Configuración API
│   │   │   └── 📄 outputs.tf             ← URL del API
│   │   │
│   │   ├── 📁 sqs/                       ← Módulo para SQS
│   │   │   ├── 📄 main.tf                ← Colas + DLQ + Alarmas
│   │   │   ├── 📄 variables.tf           ← Configuración colas
│   │   │   └── 📄 outputs.tf             ← ARNs de colas
│   │   │
│   │   └── 📁 monitoring/                ← Módulo para CloudWatch
│   │       ├── 📄 main.tf                ← Dashboard + Alarmas + SNS
│   │       ├── 📄 variables.tf           ← Configuración monitoreo
│   │       └── 📄 outputs.tf             ← ARNs de recursos
│   │
│   └── 📁 environments/                  ← Configuración por ambiente
│       │
│       ├── 📁 dev/                       ← Ambiente de DESARROLLO
│       │   ├── 📄 main.tf                ← Infraestructura completa DEV
│       │   ├── 📄 variables.tf           ← Variables DEV
│       │   ├── 📄 terraform.tfvars       ← Valores DEV (Free Tier)
│       │   └── 📄 outputs.tf             ← URLs y ARNs DEV
│       │
│       └── 📁 prod/                      ← Ambiente de PRODUCCIÓN
│           ├── 📄 main.tf                ← Infraestructura completa PROD
│           ├── 📄 variables.tf           ← Variables PROD
│           ├── 📄 terraform.tfvars       ← Valores PROD (Optimizado)
│           └── 📄 outputs.tf             ← URLs y ARNs PROD
│
├── 📁 backend/                           ← Código de funciones Lambda
│   │
│   ├── 📁 ordenes/                       ← Lambda: Procesar Órdenes
│   │   ├── 📄 main.py                    ← Handler principal (CREATE/GET)
│   │   ├── 📄 requirements.txt           ← Dependencias Python
│   │   └── 📁 tests/
│   │       └── 📄 test_main.py           ← Tests unitarios
│   │
│   ├── 📁 tracking/                      ← Lambda: Tracking
│   │   ├── 📄 handler.py                 ← Handler tracking (GET/PUT)
│   │   └── 📄 requirements.txt           ← Dependencias
│   │
│   ├── 📁 rutas/                         ← Lambda: Optimización Rutas
│   │   ├── 📄 optimizer.py               ← Algoritmo de optimización
│   │   └── 📄 requirements.txt           ← Dependencias
│   │
│   └── 📁 notificaciones/                ← Lambda: Notificaciones
│       ├── 📄 notify.py                  ← Handler SQS consumer
│       └── 📄 requirements.txt           ← Dependencias
│
├── 📁 ansible/                           ← Automatización post-deploy
│   ├── 📄 playbook.yml                   ← Playbook de configuración
│   └── 📄 inventory.ini                  ← Inventario localhost
│
└── 📁 docs/                              ← Documentación técnica
    ├── 📄 ARQUITECTURA.md                ← Detalles técnicos completos
    ├── 📄 JUSTIFICACION.md               ← Análisis costo-beneficio
    └── 📁 diagrams/                      ← Diagramas (se generan)
```

---

## Pasos de Deployment

### 🟢 PASO 1: Bootstrap (Crear Backend de Terraform)

**Qué hace**: Crea el bucket S3 y tabla DynamoDB para el estado remoto de Terraform

```bash
cd infra/bootstrap
terraform init
terraform apply -auto-approve
```

**Recursos creados**:
- ✅ S3 Bucket: `dinex-terraform-state-bucket`
- ✅ DynamoDB Table: `dinex-terraform-state-lock`

**Costo**: $0 (dentro de Free Tier)

---

### 🟢 PASO 2: Empaquetar Funciones Lambda

**Qué hace**: Empaqueta el código Python de cada Lambda con sus dependencias en archivos `.zip`

```bash
# Desde la raíz del proyecto
make deploy-lambda
```

**Archivos generados**:
- ✅ `backend/ordenes/function.zip`
- ✅ `backend/tracking/function.zip`
- ✅ `backend/rutas/function.zip`
- ✅ `backend/notificaciones/function.zip`

---

### 🟢 PASO 3: Deploy a DEV

**Qué hace**: Despliega toda la infraestructura en ambiente de desarrollo

```bash
# Opción A: Usando Make (recomendado)
make init ENV=dev
make plan ENV=dev
make apply ENV=dev

# Opción B: Terraform directo
cd infra/environments/dev
terraform init
terraform plan
terraform apply
```

**Recursos creados** (23 recursos):

#### DynamoDB (3 tablas)
- ✅ `dinex-dev-orders` (con 2 GSI)
- ✅ `dinex-dev-tracking` (con 1 GSI)
- ✅ `dinex-dev-routes` (con 1 GSI)

#### Lambda (4 funciones)
- ✅ `dinex-dev-process-orders` (256 MB, 30s timeout)
- ✅ `dinex-dev-update-tracking` (256 MB, 30s timeout)
- ✅ `dinex-dev-optimize-routes` (512 MB, 60s timeout)
- ✅ `dinex-dev-send-notifications` (256 MB, 30s timeout)

#### IAM (4 roles + 8 policies)
- ✅ Roles con permisos mínimos para cada Lambda

#### SQS (4 colas)
- ✅ `dinex-dev-orders-queue` + DLQ
- ✅ `dinex-dev-notifications-queue` + DLQ

#### API Gateway
- ✅ REST API: `dinex-dev-api`
- ✅ 5 endpoints configurados
- ✅ Stage: `dev`
- ✅ Rate limiting: 100 req/s

#### CloudWatch
- ✅ Dashboard: `dinex-dev-dashboard`
- ✅ 10+ alarmas configuradas
- ✅ 4 Log Groups (uno por Lambda)
- ✅ SNS Topic para notificaciones

**Tiempo**: 5-10 minutos

**Costo**: $0-20/mes (dentro de Free Tier)

---

### 🟢 PASO 4: Verificar Deployment

```bash
# Ver outputs (URL del API, nombres de recursos)
make output ENV=dev

# Probar API
API_URL=$(cd infra/environments/dev && terraform output -raw api_gateway_url)
curl -X POST $API_URL/orders \
  -H "Content-Type: application/json" \
  -d '{"customer_id":"TEST001","products":[{"sku":"PROD1","quantity":1,"price":10}]}'
```

**Respuesta esperada**:
```json
{
  "message": "Orden creada exitosamente",
  "order_id": "ORD-XXXXX",
  "status": "PENDING",
  "total": 10.0
}
```

---

### 🟢 PASO 5: Configurar Monitoreo

```bash
# Ver dashboard de CloudWatch
# https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=dinex-dev-dashboard

# Configurar email para alarmas (editar terraform.tfvars)
cd infra/environments/dev
nano terraform.tfvars

# Cambiar:
alarm_email = "tu-email@example.com"

# Aplicar cambio
terraform apply
```

---

### 🟡 PASO 6 (Opcional): Deploy a PROD

**Solo después de validar DEV completamente**

```bash
make init ENV=prod
make plan ENV=prod
make apply ENV=prod
```

**Diferencias con DEV**:
- Más memoria en Lambda (512 MB vs 256 MB)
- X-Ray tracing habilitado
- Point-in-time recovery habilitado en DynamoDB
- Rate limits más altos (1000 req/s vs 100)
- Retention de logs más largo (30 días vs 7)

**Costo**: $150-300/mes (según tráfico)

---

### 🟡 PASO 7 (Opcional): Configurar CI/CD

**Requisito**: Proyecto en GitHub

```bash
# 1. Crear repositorio en GitHub
git init
git add .
git commit -m "Initial commit - DINEX IaC"
git remote add origin https://github.com/TU-USUARIO/dinex-iac.git
git push -u origin main

# 2. Configurar secrets en GitHub
# Settings → Secrets → Actions → New repository secret
```

Secrets requeridos:
- `AWS_ACCESS_KEY_ID`: Tu AWS access key
- `AWS_SECRET_ACCESS_KEY`: Tu AWS secret key
- `AWS_REGION`: us-east-1

**Workflow**:
- Push a `develop` → Deploy automático a DEV
- Push a `main` → Deploy a PROD (con aprobación manual)

---

## Comandos Útiles

### Gestión de Infraestructura

```bash
# Ver estado actual
make status ENV=dev

# Ver plan sin aplicar
make plan ENV=dev

# Aplicar cambios
make apply ENV=dev

# Destruir infraestructura
make destroy ENV=dev

# Formatear código Terraform
make format

# Validar sintaxis
make validate ENV=dev
```

### Testing

```bash
# Ejecutar tests unitarios
make test

# Test de integración
make test-integration ENV=dev
```

### Monitoreo

```bash
# Ver logs en tiempo real
make logs ENV=dev

# Ver outputs (URLs, ARNs)
make output ENV=dev

# Ver costos estimados
make cost-estimate ENV=dev
```

### Limpieza

```bash
# Limpiar archivos temporales
make clean

# Limpiar todo (incluye .zip de Lambda)
rm -rf backend/**/function.zip
rm -rf backend/**/package/
```

---

## Troubleshooting Común

### ❌ Error: "Bucket already exists"

**Causa**: El nombre del bucket S3 debe ser único globalmente

**Solución**:
```bash
# Editar infra/bootstrap/variables.tf
variable "state_bucket_name" {
  default = "dinex-terraform-state-bucket-TU-NOMBRE-UNICO"
}
```

### ❌ Error: "Invalid provider configuration"

**Causa**: AWS credentials no configuradas

**Solución**:
```bash
aws configure
# Introduce tus credenciales
```

### ❌ Error: "Lambda function code not found"

**Causa**: Funciones Lambda no empaquetadas

**Solución**:
```bash
make deploy-lambda
make apply ENV=dev
```

### ❌ Error: "API Gateway throttling"

**Causa**: Límite de rate excedido

**Solución**:
```hcl
# Editar infra/environments/dev/terraform.tfvars
api_throttle_rate_limit = 500  # Aumentar de 100 a 500
```

### ❌ Error: "DynamoDB throttling"

**Causa**: Capacidad insuficiente

**Solución**:
```hcl
# El billing mode PAY_PER_REQUEST auto-escala
# Si usas PROVISIONED, aumenta capacidad:
read_capacity  = 10  # Default: 5
write_capacity = 10  # Default: 5
```

---

## Checklist de Deployment

### Pre-deployment
- [ ] AWS cuenta creada
- [ ] Herramientas instaladas (terraform, aws-cli, python)
- [ ] AWS credentials configuradas
- [ ] Proyecto clonado/descargado

### Bootstrap
- [ ] `terraform init` en bootstrap exitoso
- [ ] `terraform apply` en bootstrap exitoso
- [ ] S3 bucket creado
- [ ] DynamoDB table creada

### Lambda Packaging
- [ ] `make deploy-lambda` ejecutado
- [ ] 4 archivos `.zip` creados en backend/

### Infrastructure Deployment
- [ ] `make init ENV=dev` exitoso
- [ ] `make plan ENV=dev` revisado
- [ ] `make apply ENV=dev` exitoso
- [ ] 23 recursos creados

### Verification
- [ ] API Gateway URL obtenida
- [ ] POST /orders funciona
- [ ] GET /orders funciona
- [ ] CloudWatch Dashboard accesible
- [ ] Logs visibles en CloudWatch

### Monitoring
- [ ] Email configurado en terraform.tfvars
- [ ] SNS subscription confirmada
- [ ] Alarmas funcionando

### Optional
- [ ] CI/CD configurado en GitHub
- [ ] Ambiente PROD desplegado
- [ ] Tests automatizados ejecutándose

---

## Costos Finales

### DEV (Free Tier)

```
API Gateway:    $3.50
Lambda:         $0 (Free Tier)
DynamoDB:       $0 (Free Tier)
SQS:            $0 (Free Tier)
CloudWatch:     $5
S3:             $0 (Free Tier)
─────────────────────
TOTAL:          $8.50/mes
```

### PROD (10K requests/día)

```
API Gateway:    $10
Lambda:         $20
DynamoDB:       $100
SQS:            $5
CloudWatch:     $20
S3:             $1
─────────────────────
TOTAL:          $156/mes
```

---

## Próximos Pasos

1. ✅ **Completar deployment a DEV**
2. ✅ **Validar con tests de integración**
3. ✅ **Configurar monitoreo y alarmas**
4. ✅ **Documentar en README del repo**
5. ⬜ **Presentar proyecto en clase**
6. ⬜ **Demo en vivo (opcional)**
7. ⬜ **Deploy a PROD (si es necesario)**

---

## Recursos de Ayuda

- 📖 [README.md](README.md) - Documentación principal
- 🚀 [QUICKSTART.md](QUICKSTART.md) - Inicio rápido
- 🏗️ [ARQUITECTURA.md](docs/ARQUITECTURA.md) - Detalles técnicos
- 💰 [JUSTIFICACION.md](docs/JUSTIFICACION.md) - Análisis de costos
- 🌐 [AWS Free Tier](https://aws.amazon.com/free/)
- 📘 [Terraform Docs](https://www.terraform.io/docs)

---

**¡Éxito con tu proyecto universitario! 🎓🚀**
