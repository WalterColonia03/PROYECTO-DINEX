# Arquitectura Técnica - DINEX Perú

## Índice
1. [Visión General](#visión-general)
2. [Componentes de la Arquitectura](#componentes-de-la-arquitectura)
3. [Flujos de Datos](#flujos-de-datos)
4. [Diseño de Base de Datos](#diseño-de-base-de-datos)
5. [Seguridad](#seguridad)
6. [Escalabilidad](#escalabilidad)
7. [Alta Disponibilidad](#alta-disponibilidad)
8. [Monitoreo y Observabilidad](#monitoreo-y-observabilidad)

---

## Visión General

DINEX Perú implementa una **arquitectura serverless event-driven** completamente gestionada en AWS, diseñada para:

- **Escalabilidad automática**: De 0 a 10,000+ solicitudes por segundo
- **Pago por uso**: Solo pagas por los recursos que consumes
- **Alta disponibilidad**: 99.9% SLA garantizado por AWS
- **Bajo mantenimiento**: Sin servidores que gestionar

### Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                         CAPA DE CLIENTE                         │
│  (Web App, Mobile App, Partners, Internal Systems)             │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ HTTPS
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      AMAZON API GATEWAY                         │
│  - Rate Limiting (100 req/s)                                   │
│  - Throttling (burst 50)                                       │
│  - CORS habilitado                                             │
│  - CloudWatch Logs                                             │
└───┬─────────┬─────────┬─────────┬───────────────────────────────┘
    │         │         │         │
    ▼         ▼         ▼         ▼
┌─────────┐ ┌────────┐ ┌──────┐ ┌──────────┐
│ Lambda  │ │ Lambda │ │Lambda│ │  Lambda  │
│ Orders  │ │Tracking│ │Routes│ │  Notify  │
│         │ │        │ │      │ │          │
│ Python  │ │ Python │ │Python│ │  Python  │
│  3.11   │ │  3.11  │ │ 3.11 │ │   3.11   │
└────┬────┘ └───┬────┘ └──┬───┘ └────▲─────┘
     │          │          │          │
     │          │          │          │
     ▼          ▼          ▼          │
┌────────────────────────────────────┐│
│          DYNAMODB TABLES            ││
│  ┌─────────────────────────────┐   ││
│  │ Orders Table                │   ││
│  │ - PK: order_id              │   ││
│  │ - SK: created_at            │   ││
│  │ - GSI: customer_index       │   ││
│  │ - GSI: status_index         │   ││
│  │ - TTL: 30 días              │   ││
│  │ - Stream: habilitado        │   ││
│  └─────────────────────────────┘   ││
│                                     ││
│  ┌─────────────────────────────┐   ││
│  │ Tracking Table              │   ││
│  │ - PK: tracking_id           │   ││
│  │ - SK: timestamp             │   ││
│  │ - GSI: order_index          │   ││
│  └─────────────────────────────┘   ││
│                                     ││
│  ┌─────────────────────────────┐   ││
│  │ Routes Table                │   ││
│  │ - PK: route_id              │   ││
│  │ - GSI: driver_index         │   ││
│  └─────────────────────────────┘   ││
└─────────────────────────────────────┘│
     │                                 │
     ▼                                 │
┌──────────────────────┐               │
│    AMAZON SQS        │───────────────┘
│  ┌────────────────┐  │
│  │ Orders Queue   │  │
│  │ - DLQ enabled  │  │
│  └────────────────┘  │
│  ┌────────────────┐  │
│  │ Notify Queue   │  │
│  │ - DLQ enabled  │  │
│  └────────────────┘  │
└──────────────────────┘
     │
     ▼
┌────────────────────────────────────┐
│      AMAZON CLOUDWATCH             │
│  - Logs                            │
│  - Metrics                         │
│  - Alarms                          │
│  - Dashboard                       │
│  - X-Ray (opcional)                │
└────────────────────────────────────┘
```

---

## Componentes de la Arquitectura

### 1. Amazon API Gateway

**Propósito**: Punto de entrada único para todas las solicitudes HTTP

**Características**:
- REST API pública
- Endpoints:
  - `POST /orders` - Crear nueva orden
  - `GET /orders` - Listar órdenes
  - `GET /tracking` - Consultar tracking
  - `PUT /tracking` - Actualizar tracking
  - `POST /routes` - Optimizar rutas
- Rate limiting: 100 req/s (configurable)
- Burst limit: 50 requests
- CORS habilitado para integraciones web
- CloudWatch Logs para auditoría

**Free Tier**: 1M llamadas/mes

### 2. AWS Lambda Functions

#### Lambda: Process Orders
- **Archivo**: `backend/ordenes/main.py`
- **Runtime**: Python 3.11
- **Memoria**: 256 MB
- **Timeout**: 30 segundos
- **Triggers**: API Gateway (POST/GET /orders)
- **Funcionalidad**:
  - Crear nuevas órdenes
  - Validar datos de entrada
  - Calcular totales
  - Persistir en DynamoDB
  - Enviar notificaciones a SQS

#### Lambda: Update Tracking
- **Archivo**: `backend/tracking/handler.py`
- **Runtime**: Python 3.11
- **Memoria**: 256 MB
- **Timeout**: 30 segundos
- **Triggers**: API Gateway (GET/PUT /tracking)
- **Funcionalidad**:
  - Consultar estado de tracking
  - Actualizar ubicación de órdenes
  - Registrar eventos de tracking
  - Actualizar estado de órdenes

#### Lambda: Optimize Routes
- **Archivo**: `backend/rutas/optimizer.py`
- **Runtime**: Python 3.11
- **Memoria**: 512 MB (más memoria para cálculos)
- **Timeout**: 60 segundos
- **Triggers**: API Gateway (POST /routes)
- **Funcionalidad**:
  - Optimizar rutas de entrega
  - Algoritmo Nearest Neighbor
  - Calcular distancias
  - Asignar órdenes a conductores

#### Lambda: Send Notifications
- **Archivo**: `backend/notificaciones/notify.py`
- **Runtime**: Python 3.11
- **Memoria**: 256 MB
- **Timeout**: 30 segundos
- **Triggers**: SQS (notifications-queue)
- **Funcionalidad**:
  - Procesar mensajes de SQS
  - Enviar confirmaciones de órdenes
  - Notificar actualizaciones de tracking
  - (En producción: integrar con SES/SNS)

**Free Tier**: 1M invocaciones/mes + 400,000 GB-s

### 3. Amazon DynamoDB

#### Tabla: Orders
```
Primary Key:
  - Partition Key: order_id (String)
  - Sort Key: created_at (String)

Attributes:
  - customer_id (String)
  - products (List)
  - delivery_address (String)
  - status (String)
  - total (Number)
  - ttl (Number)

Global Secondary Indexes:
  1. customer_index
     - PK: customer_id
     - SK: created_at
     - Projection: ALL

  2. status_index
     - PK: status
     - SK: created_at
     - Projection: ALL

Features:
  - TTL: 30 días (limpieza automática)
  - Streams: Habilitado (para eventos)
  - Encryption: At rest (AES-256)
```

#### Tabla: Tracking
```
Primary Key:
  - Partition Key: tracking_id (String)
  - Sort Key: timestamp (String)

Attributes:
  - order_id (String)
  - status (String)
  - location (String)

Global Secondary Index:
  - order_index (consultas por orden)
```

#### Tabla: Routes
```
Primary Key:
  - Partition Key: route_id (String)

Attributes:
  - driver_id (String)
  - order_ids (List)
  - stops (Number)
  - estimated_distance_km (Number)
  - status (String)

Global Secondary Index:
  - driver_index (consultas por conductor)
```

**Billing Mode**: PAY_PER_REQUEST (on-demand)
**Free Tier**: 25 GB storage + 25 WCU/RCU

### 4. Amazon SQS

#### Queue: orders-queue
- **Uso**: Procesamiento asíncrono de órdenes
- **Visibility Timeout**: 300 segundos
- **Dead Letter Queue**: Habilitada (3 intentos)
- **Encryption**: SQS managed

#### Queue: notifications-queue
- **Uso**: Cola de notificaciones a clientes
- **Visibility Timeout**: 60 segundos
- **Dead Letter Queue**: Habilitada
- **Long Polling**: 20 segundos

**Free Tier**: 1M requests/mes

### 5. Amazon CloudWatch

#### Logs
- Retención: 7 días (dev), 30 días (prod)
- Log Groups:
  - `/aws/lambda/dinex-dev-process-orders`
  - `/aws/lambda/dinex-dev-update-tracking`
  - `/aws/lambda/dinex-dev-optimize-routes`
  - `/aws/lambda/dinex-dev-send-notifications`
  - `/aws/apigateway/dinex-dev-api`

#### Metrics
- Lambda: Invocations, Errors, Duration, Throttles
- DynamoDB: ConsumedCapacity, ThrottledRequests
- API Gateway: Count, 4XXError, 5XXError, Latency
- SQS: NumberOfMessagesSent, ApproximateAgeOfOldestMessage

#### Alarms
- Lambda Errors > 5 en 5 minutos
- API Latency > 2 segundos
- DynamoDB Throttling
- SQS Messages > 1000

**Free Tier**: 5 GB logs + 10 métricas custom

---

## Flujos de Datos

### Flujo 1: Creación de Orden

```
1. Cliente → API Gateway: POST /orders
2. API Gateway → Lambda (Process Orders)
3. Lambda valida datos
4. Lambda → DynamoDB (Orders): put_item()
5. Lambda → SQS (Notifications): send_message()
6. Lambda → Cliente: 201 Created + order_id
7. SQS → Lambda (Notifications): trigger
8. Lambda envía notificación
```

### Flujo 2: Consulta de Tracking

```
1. Cliente → API Gateway: GET /tracking?order_id=XXX
2. API Gateway → Lambda (Tracking)
3. Lambda → DynamoDB (Tracking): query() con GSI
4. Lambda → Cliente: 200 OK + tracking events
```

### Flujo 3: Optimización de Rutas

```
1. Cliente → API Gateway: POST /routes
   Body: { order_ids: [...], driver_id: "DRV001" }
2. API Gateway → Lambda (Routes)
3. Lambda → DynamoDB (Orders): batch_get_item()
4. Lambda ejecuta algoritmo de optimización
5. Lambda → DynamoDB (Routes): put_item()
6. Lambda → Cliente: 200 OK + route_id + secuencia optimizada
```

---

## Diseño de Base de Datos

### Patrones de Acceso

1. **Crear orden**: PutItem en Orders
2. **Obtener orden por ID**: Query en Orders (PK = order_id)
3. **Listar órdenes de cliente**: Query en customer_index
4. **Listar órdenes por estado**: Query en status_index
5. **Crear evento de tracking**: PutItem en Tracking
6. **Obtener tracking de orden**: Query en order_index
7. **Crear ruta**: PutItem en Routes
8. **Obtener rutas de conductor**: Query en driver_index

### Estrategia de Particionamiento

- **Orders**: Partition key = order_id (UUID único) → Distribución uniforme
- **Tracking**: Partition key = tracking_id → Distribución uniforme
- **Routes**: Partition key = route_id → Distribución uniforme

### Optimizaciones

- **GSI**: Índices secundarios para consultas frecuentes
- **TTL**: Limpieza automática de datos antiguos (ahorro de costos)
- **Streams**: Captura de cambios para procesamiento asíncrono
- **On-Demand**: Billing automático basado en uso real

---

## Seguridad

### Autenticación y Autorización

- **API Gateway**: API Keys (opcional)
- **IAM Roles**: Least privilege para cada Lambda
- **Secrets Manager**: Para credenciales (si es necesario)

### Cifrado

- **En tránsito**: HTTPS/TLS 1.2+
- **En reposo**:
  - DynamoDB: Encryption at rest (AES-256)
  - S3: Server-side encryption
  - SQS: SQS managed encryption

### Network Security

- **API Gateway**: Rate limiting y throttling
- **Lambda**: Sin acceso público directo
- **VPC**: Opcional para conectar con recursos privados

### Compliance

- CloudTrail habilitado (auditoría)
- CloudWatch Logs (registro de actividad)
- Checkov scans en CI/CD

---

## Escalabilidad

### Auto-Scaling

- **Lambda**: Escalado automático (0 → miles de instancias)
- **DynamoDB**: On-demand auto-scaling
- **API Gateway**: Manejado por AWS

### Límites

- Lambda concurrencia: 1000 (soft limit, aumentable)
- DynamoDB: Ilimitado con on-demand
- API Gateway: 10,000 req/s por región

### Performance

- **Latencia p99**: < 1 segundo
- **Throughput**: 10,000+ req/s
- **Cold starts**: < 500ms (Python 3.11)

---

## Alta Disponibilidad

### Multi-AZ

Todos los servicios son multi-AZ por defecto:
- Lambda: Desplegado en múltiples AZs
- DynamoDB: Replicación síncrona
- SQS: Datos replicados

### Disaster Recovery

- **RTO**: < 1 hora
- **RPO**: < 5 minutos (con Point-in-time recovery)
- **Backup**: DynamoDB PITR en producción

### Failover

- Lambda: Retry automático
- SQS: DLQ para mensajes fallidos
- DynamoDB: Automatic failover

---

## Monitoreo y Observabilidad

### Métricas Clave (KPIs)

1. **Disponibilidad**: % uptime del API
2. **Latencia**: p50, p95, p99 de respuestas
3. **Error Rate**: % de requests con error
4. **Throughput**: Requests por segundo
5. **Costos**: $ por mes

### Dashboard

CloudWatch Dashboard incluye:
- Lambda invocations y errors
- API Gateway requests y latencia
- DynamoDB capacity usage
- SQS queue depth

### Alertas

1. Lambda errors > 5 → Email
2. API latency > 2s → Email
3. DynamoDB throttling → Email
4. Costos > $100 → Email

---

## Conclusiones

Esta arquitectura proporciona:

✅ **Escalabilidad infinita** sin provisionar servidores
✅ **99.9% disponibilidad** garantizada por AWS
✅ **Costos optimizados** con Free Tier ($0-20/mes en dev)
✅ **Mantenimiento mínimo** sin infraestructura que gestionar
✅ **Seguridad robusta** con cifrado y IAM
✅ **Monitoreo completo** con CloudWatch

**Ideal para**: Startups, MVPs, aplicaciones con tráfico variable, proyectos universitarios
