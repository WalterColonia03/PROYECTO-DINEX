# Guía de Configuración AWS - Proyecto DINEX Tracking

**Estudiante:** [Tu Nombre]
**Proyecto:** Sistema de Tracking de Entregas DINEX
**Curso:** Infraestructura como Código

---

## Tabla de Contenidos

1. [Errores Identificados y Soluciones](#errores-identificados-y-soluciones)
2. [Requisitos Previos](#requisitos-previos)
3. [Paso 1: Crear Cuenta de AWS](#paso-1-crear-cuenta-de-aws)
4. [Paso 2: Configurar AWS CLI](#paso-2-configurar-aws-cli)
5. [Paso 3: Instalar Terraform](#paso-3-instalar-terraform)
6. [Paso 4: Configurar Credenciales AWS](#paso-4-configurar-credenciales-aws)
7. [Paso 5: Personalizar Configuración del Proyecto](#paso-5-personalizar-configuración-del-proyecto)
8. [Paso 6: Desplegar la Infraestructura](#paso-6-desplegar-la-infraestructura)
9. [Verificación del Deployment](#verificación-del-deployment)
10. [Solución de Problemas Comunes](#solución-de-problemas-comunes)

---

## Errores Identificados y Soluciones

### ✅ Error 1: Rutas incorrectas en main.tf (SOLUCIONADO)

**Problema:**
```hcl
filename = "${path.module}/../lambda-simple/tracking/deployment.zip"
```

**Causa:** Las rutas apuntaban a directorios `lambda-simple` que fueron renombrados a `lambda`.

**Solución aplicada:**
```hcl
filename = "${path.module}/../lambda/tracking/deployment.zip"
```

Este error ha sido corregido automáticamente en las líneas 193, 210, 267 y 272 de `terraform/main.tf`.

---

### ⚠️ Error 2: Terraform no instalado (REQUIERE ACCIÓN)

**Problema:**
```
/usr/bin/bash: line 1: terraform: command not found
```

**Causa:** Terraform no está instalado en tu sistema.

**Solución:** Ver [Paso 3: Instalar Terraform](#paso-3-instalar-terraform)

---

### ⚠️ Error 3: Credenciales AWS no configuradas (REQUIERE ACCIÓN)

**Problema esperado al ejecutar `terraform init` o `terraform plan`:**
```
Error: No valid credential sources found for AWS Provider
```

**Causa:** Terraform necesita credenciales de AWS para crear recursos en tu cuenta.

**Solución:** Ver [Paso 4: Configurar Credenciales AWS](#paso-4-configurar-credenciales-aws)

---

### ⚠️ Error 4: Valores por defecto en terraform.tfvars (REQUIERE ACCIÓN)

**Problema:**
```hcl
student_name = "Tu Nombre Aquí"
```

**Causa:** Debes personalizar los valores con tu información real.

**Solución:** Ver [Paso 5: Personalizar Configuración del Proyecto](#paso-5-personalizar-configuración-del-proyecto)

---

## Requisitos Previos

Antes de comenzar, asegúrate de tener:

- [ ] Una computadora con Windows, macOS o Linux
- [ ] Conexión a internet estable
- [ ] Una tarjeta de crédito/débito válida (necesaria para crear cuenta AWS, pero NO se cobrará si usas solo Free Tier)
- [ ] Acceso a un correo electrónico
- [ ] Conocimientos básicos de línea de comandos (terminal/cmd)

---

## Paso 1: Crear Cuenta de AWS

### 1.1 Registrarse en AWS

1. Abre tu navegador y ve a: https://aws.amazon.com/
2. Haz clic en **"Crear una cuenta de AWS"** (esquina superior derecha)
3. Completa el formulario con tu información:
   - **Dirección de correo electrónico:** Tu email personal o académico
   - **Nombre de la cuenta AWS:** Por ejemplo, "DINEX-Proyecto-[TuNombre]"
   - **Contraseña:** Elige una contraseña segura

4. Haz clic en **"Continuar"**

### 1.2 Información de Contacto

1. Selecciona el tipo de cuenta:
   - **Personal** (recomendado para estudiantes)

2. Completa tu información personal:
   - Nombre completo
   - Número de teléfono
   - Dirección completa

3. Lee y acepta el **Acuerdo de cliente de AWS**
4. Haz clic en **"Crear cuenta y continuar"**

### 1.3 Información de Pago

**IMPORTANTE:** AWS requiere una tarjeta de crédito/débito para verificar tu identidad, PERO:
- NO te cobrarán si te mantienes dentro del Free Tier
- Este proyecto está diseñado para NO superar los límites gratuitos
- Puedes configurar alertas de facturación (recomendado)

1. Ingresa la información de tu tarjeta de crédito o débito
2. Completa la dirección de facturación
3. Haz clic en **"Verificar y agregar"**

### 1.4 Verificación de Identidad

1. Selecciona el método de verificación:
   - **Mensaje de texto (SMS)** (más rápido)
   - **Llamada telefónica**

2. Ingresa tu número de teléfono
3. Ingresa el código de verificación que recibes
4. Haz clic en **"Continuar"**

### 1.5 Seleccionar Plan de Soporte

1. Selecciona **"Plan de soporte básico"** (GRATIS)
2. Haz clic en **"Completar registro"**

**¡Felicidades!** Tu cuenta de AWS está creada.

### 1.6 Acceder a la Consola de AWS

1. Espera 5-10 minutos para que la cuenta se active completamente
2. Ve a: https://console.aws.amazon.com/
3. Haz clic en **"Iniciar sesión en la consola"**
4. Selecciona **"Usuario raíz"**
5. Ingresa tu correo electrónico y contraseña

---

## Paso 2: Configurar AWS CLI

### 2.1 Instalar AWS CLI en Windows

#### Opción A: Instalador MSI (Recomendado)

1. Descarga el instalador desde: https://awscli.amazonaws.com/AWSCLIV2.msi
2. Ejecuta el archivo descargado
3. Sigue el asistente de instalación
4. Acepta los términos y condiciones
5. Haz clic en **"Install"**
6. Completa la instalación

#### Verificar la instalación:

```powershell
aws --version
```

**Salida esperada:**
```
aws-cli/2.x.x Python/3.x.x Windows/10 exe/AMD64
```

### 2.2 Instalar AWS CLI en macOS

#### Opción A: Homebrew (Recomendado si ya tienes Homebrew)

```bash
brew install awscli
```

#### Opción B: Instalador PKG

1. Descarga: https://awscli.amazonaws.com/AWSCLIV2.pkg
2. Ejecuta el archivo descargado
3. Sigue el asistente de instalación

#### Verificar la instalación:

```bash
aws --version
```

### 2.3 Instalar AWS CLI en Linux

#### Ubuntu/Debian:

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

#### Verificar la instalación:

```bash
aws --version
```

---

## Paso 3: Instalar Terraform

### 3.1 Instalar Terraform en Windows

#### Opción A: Chocolatey (Recomendado)

1. Abre PowerShell como Administrador
2. Si no tienes Chocolatey, instálalo primero:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

3. Instala Terraform:

```powershell
choco install terraform
```

#### Opción B: Instalación Manual

1. Ve a: https://www.terraform.io/downloads
2. Descarga el archivo ZIP para Windows
3. Extrae el archivo `terraform.exe`
4. Mueve `terraform.exe` a `C:\Program Files\Terraform\`
5. Agrega `C:\Program Files\Terraform\` a la variable PATH:
   - Busca "variables de entorno" en el menú de Windows
   - Haz clic en "Variables de entorno"
   - En "Variables del sistema", selecciona "Path" y haz clic en "Editar"
   - Haz clic en "Nuevo" y agrega `C:\Program Files\Terraform\`
   - Haz clic en "Aceptar" en todas las ventanas

#### Verificar la instalación:

```powershell
terraform version
```

**Salida esperada:**
```
Terraform v1.6.x
```

### 3.2 Instalar Terraform en macOS

#### Opción A: Homebrew (Recomendado)

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

#### Verificar la instalación:

```bash
terraform version
```

### 3.3 Instalar Terraform en Linux

#### Ubuntu/Debian:

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

#### Verificar la instalación:

```bash
terraform version
```

---

## Paso 4: Configurar Credenciales AWS

### 4.1 Crear Access Keys en AWS

**IMPORTANTE:** Las Access Keys dan acceso completo a tu cuenta AWS. NUNCA las compartas ni las subas a GitHub.

#### 4.1.1 Acceder a IAM

1. Inicia sesión en la consola de AWS: https://console.aws.amazon.com/
2. En la barra de búsqueda superior, escribe **"IAM"**
3. Haz clic en **"IAM"** (Identity and Access Management)

#### 4.1.2 Crear un Usuario IAM (Recomendado - Más Seguro)

**Opción A: Usuario IAM (RECOMENDADO para seguridad)**

1. En el panel izquierdo, haz clic en **"Users"** (Usuarios)
2. Haz clic en **"Create user"** (Crear usuario)
3. Nombre del usuario: `terraform-dinex`
4. Marca la casilla: **"Provide user access to the AWS Management Console"** (Opcional)
5. Haz clic en **"Next"**

6. **Configurar permisos:**
   - Selecciona **"Attach policies directly"**
   - Busca y selecciona las siguientes políticas:
     - ✅ `AmazonDynamoDBFullAccess`
     - ✅ `AWSLambda_FullAccess`
     - ✅ `AmazonAPIGatewayAdministrator`
     - ✅ `CloudWatchFullAccess`
     - ✅ `AmazonSNSFullAccess`
     - ✅ `IAMFullAccess` (necesario para que Terraform cree roles)

7. Haz clic en **"Next"**
8. Revisa la información y haz clic en **"Create user"**

#### 4.1.3 Crear Access Keys para el Usuario

1. En la lista de usuarios, haz clic en **`terraform-dinex`**
2. Haz clic en la pestaña **"Security credentials"**
3. Desplázate hasta **"Access keys"**
4. Haz clic en **"Create access key"**
5. Selecciona el caso de uso: **"Command Line Interface (CLI)"**
6. Marca la casilla de confirmación en la parte inferior
7. Haz clic en **"Next"**
8. (Opcional) Agrega una descripción: "Terraform para proyecto DINEX"
9. Haz clic en **"Create access key"**

**IMPORTANTE:**
- Se mostrarán dos valores:
  - **Access key ID:** Ejemplo: `AKIAIOSFODNN7EXAMPLE`
  - **Secret access key:** Ejemplo: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`

- **¡GUARDA ESTOS VALORES INMEDIATAMENTE!**
- **El Secret access key SOLO se muestra UNA VEZ**
- Haz clic en **"Download .csv file"** para guardar las credenciales
- Guarda el archivo en un lugar seguro (NO en el repositorio del proyecto)

---

**Opción B: Credenciales de Usuario Raíz (NO RECOMENDADO - Solo para pruebas rápidas)**

⚠️ **ADVERTENCIA:** Usar el usuario raíz es menos seguro. Solo úsalo si tienes problemas creando el usuario IAM.

1. En la consola de AWS, haz clic en tu nombre (esquina superior derecha)
2. Haz clic en **"Security credentials"**
3. Desplázate hasta **"Access keys"**
4. Haz clic en **"Create access key"**
5. Se mostrará una advertencia - haz clic en **"Create access key"** nuevamente
6. Guarda el **Access key ID** y **Secret access key** (solo se muestra una vez)

---

### 4.2 Configurar AWS CLI con las Credenciales

#### 4.2.1 Configuración Interactiva (Recomendado)

Abre tu terminal (cmd, PowerShell, o terminal de Linux/macOS) y ejecuta:

```bash
aws configure
```

Se te pedirá la siguiente información:

```
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: us-east-1
Default output format [None]: json
```

**Explicación:**
- **Access Key ID:** Pega el valor que guardaste anteriormente
- **Secret Access Key:** Pega el secret key que guardaste
- **Default region name:** `us-east-1` (región de Virginia, USA)
- **Default output format:** `json` (formato de salida de comandos)

#### 4.2.2 Verificar la Configuración

```bash
aws sts get-caller-identity
```

**Salida esperada:**
```json
{
    "UserId": "AIDACKCEVSQ6C2EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/terraform-dinex"
}
```

Si ves esta salida, **¡tus credenciales están configuradas correctamente!** ✅

#### 4.2.3 Ubicación de las Credenciales

Las credenciales se guardan en:

**Windows:**
```
C:\Users\TuUsuario\.aws\credentials
C:\Users\TuUsuario\.aws\config
```

**macOS/Linux:**
```
~/.aws/credentials
~/.aws/config
```

**Contenido del archivo `credentials`:**
```ini
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

**Contenido del archivo `config`:**
```ini
[default]
region = us-east-1
output = json
```

---

### 4.3 Variables de Entorno (Alternativa)

Si prefieres no usar archivos de configuración, puedes configurar variables de entorno:

#### Windows (PowerShell):

```powershell
$env:AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
$env:AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
$env:AWS_DEFAULT_REGION="us-east-1"
```

#### macOS/Linux:

```bash
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_DEFAULT_REGION="us-east-1"
```

---

## Paso 5: Personalizar Configuración del Proyecto

### 5.1 Editar terraform.tfvars

1. Abre el archivo `terraform/terraform.tfvars` en tu editor de código
2. Reemplaza los valores por defecto con tu información:

**ANTES:**
```hcl
student_name = "Tu Nombre Aquí"

additional_tags = {
  Universidad = "Tu Universidad"
  Curso       = "Infraestructura como Código"
  Semestre    = "2025-1"
}
```

**DESPUÉS (ejemplo):**
```hcl
student_name = "Juan Pérez"

additional_tags = {
  Universidad = "Universidad Nacional Mayor de San Marcos"
  Curso       = "Infraestructura como Código"
  Semestre    = "2025-1"
}
```

### 5.2 Verificar Otras Configuraciones

El archivo `terraform.tfvars` contiene otras configuraciones que puedes revisar:

```hcl
# Región de AWS (puedes cambiarla si lo deseas)
aws_region = "us-east-1"

# Ambiente (dev, staging, prod)
environment = "dev"

# Nombre del proyecto (NO cambiar a menos que sea necesario)
project = "dinex"

# Límites de API Gateway
api_throttle_rate  = 100  # 100 requests por segundo
api_throttle_burst = 50   # Burst de 50 requests

# Threshold de alarmas
alarm_error_threshold = 5  # Alarma después de 5 errores
```

**Recomendación:** Deja estos valores tal como están para tu primera implementación.

---

## Paso 6: Desplegar la Infraestructura

### 6.1 Navegar al Directorio del Proyecto

Abre tu terminal y navega al directorio del proyecto:

```bash
cd "C:\Users\walte\Downloads\INFRAESTRUCTURA COMO CODIGO CURSO\Backend-main\INFRAESTRUCTURA DINEX"
```

(Ajusta la ruta según donde hayas guardado el proyecto)

### 6.2 Empaquetar las Funciones Lambda (Ya completado)

Las funciones Lambda ya han sido empaquetadas. Puedes verificar que existan:

```bash
ls -lh lambda/tracking/deployment.zip
ls -lh lambda/notifications/deployment.zip
```

Si no existen, ejecuta:

```bash
cd lambda/tracking
powershell -Command "Compress-Archive -Path index.py -DestinationPath deployment.zip -Force"
cd ../notifications
powershell -Command "Compress-Archive -Path index.py -DestinationPath deployment.zip -Force"
cd ../..
```

### 6.3 Inicializar Terraform

Navega al directorio de Terraform e inicializa:

```bash
cd terraform
terraform init
```

**Salida esperada:**
```
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...
- Installed hashicorp/aws v5.x.x

Terraform has been successfully initialized!
```

**Si ves errores:**
- `Error: No valid credential sources found`: Revisa el [Paso 4](#paso-4-configurar-credenciales-aws)
- `Error: Failed to install provider`: Verifica tu conexión a internet

### 6.4 Formatear el Código (Opcional)

```bash
terraform fmt
```

Este comando formatea automáticamente todos los archivos `.tf` según el estilo estándar de Terraform.

### 6.5 Validar la Sintaxis

```bash
terraform validate
```

**Salida esperada:**
```
Success! The configuration is valid.
```

### 6.6 Ver el Plan de Ejecución

Antes de crear recursos, revisa qué se va a crear:

```bash
terraform plan
```

**Salida esperada:**
```
Terraform will perform the following actions:

  # aws_apigatewayv2_api.api will be created
  + resource "aws_apigatewayv2_api" "api" {
      + api_endpoint                 = (known after apply)
      + name                         = "dinex-api-dev"
      + protocol_type                = "HTTP"
      ...
    }

  # aws_dynamodb_table.tracking will be created
  + resource "aws_dynamodb_table" "tracking" {
      + arn              = (known after apply)
      + billing_mode     = "PAY_PER_REQUEST"
      + hash_key         = "tracking_id"
      + name             = "dinex-tracking-dev"
      + range_key        = "timestamp"
      ...
    }

  ... (continúa listando todos los recursos)

Plan: 18 to add, 0 to change, 0 to destroy.
```

**Explicación:**
- **Plan: 18 to add**: Se crearán 18 recursos en AWS
- **0 to change**: No se modificará ningún recurso existente
- **0 to destroy**: No se eliminará ningún recurso

Revisa cuidadosamente esta salida para asegurarte de que todo es correcto.

### 6.7 Aplicar la Configuración (Crear Recursos)

**IMPORTANTE:** Este paso creará recursos reales en tu cuenta de AWS.

```bash
terraform apply
```

Se te pedirá confirmación:

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

Escribe `yes` y presiona Enter.

**Proceso de creación:**
```
aws_iam_role.lambda_role: Creating...
aws_dynamodb_table.tracking: Creating...
aws_sns_topic.notifications: Creating...
aws_cloudwatch_log_group.tracking: Creating...
...
Apply complete! Resources: 18 added, 0 changed, 0 destroyed.
```

**Tiempo estimado:** 3-5 minutos

### 6.8 Ver los Outputs

Al finalizar, Terraform mostrará información importante:

```
Outputs:

api_endpoint = "https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev"

api_usage_examples = <<EOT
Ejemplos de uso del API:

1. Crear/Actualizar tracking:
   curl -X POST https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev/tracking \
     -H "Content-Type: application/json" \
     -d '{...}'
...
EOT

dashboard_url = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=dinex-dashboard-dev"

dynamodb_table_name = "dinex-tracking-dev"

environment_info = {
  environment = "dev"
  project = "dinex"
  region = "us-east-1"
  student = "Juan Pérez"
}
```

**Guarda estos outputs**, especialmente el `api_endpoint`.

---

## Verificación del Deployment

### 7.1 Verificar Recursos en la Consola AWS

#### Verificar DynamoDB:

1. Ve a: https://console.aws.amazon.com/dynamodb/
2. Haz clic en **"Tables"** (Tablas)
3. Deberías ver la tabla: **`dinex-tracking-dev`**
4. Haz clic en ella para ver los detalles

#### Verificar Lambda:

1. Ve a: https://console.aws.amazon.com/lambda/
2. Deberías ver dos funciones:
   - **`dinex-tracking-dev`**
   - **`dinex-notifications-dev`**

#### Verificar API Gateway:

1. Ve a: https://console.aws.amazon.com/apigateway/
2. Deberías ver: **`dinex-api-dev`**

#### Verificar CloudWatch Dashboard:

1. Ve a: https://console.aws.amazon.com/cloudwatch/
2. Haz clic en **"Dashboards"**
3. Haz clic en **`dinex-dashboard-dev`**
4. Deberías ver un dashboard con métricas (inicialmente vacías)

### 7.2 Probar el API

#### Prueba 1: Health Check

```bash
curl https://TU-API-ENDPOINT.execute-api.us-east-1.amazonaws.com/dev/health
```

Reemplaza `TU-API-ENDPOINT` con el valor de `api_endpoint` que obtuviste en los outputs.

**Respuesta esperada:**
```json
{
  "status": "healthy",
  "service": "dinex-tracking",
  "timestamp": 1234567890
}
```

#### Prueba 2: Crear un Tracking

```bash
curl -X POST https://TU-API-ENDPOINT.execute-api.us-east-1.amazonaws.com/dev/tracking \
  -H "Content-Type: application/json" \
  -d '{
    "tracking_id": "TRK001",
    "package_id": "PKG001",
    "location": "Lima - Almacén Principal",
    "latitude": -12.0464,
    "longitude": -77.0428,
    "status": "IN_TRANSIT"
  }'
```

**Respuesta esperada:**
```json
{
  "message": "Tracking actualizado exitosamente",
  "tracking_id": "TRK001",
  "timestamp": 1234567890
}
```

#### Prueba 3: Consultar el Tracking

```bash
curl "https://TU-API-ENDPOINT.execute-api.us-east-1.amazonaws.com/dev/tracking?tracking_id=TRK001"
```

**Respuesta esperada:**
```json
{
  "Items": [
    {
      "tracking_id": "TRK001",
      "package_id": "PKG001",
      "location": "Lima - Almacén Principal",
      "latitude": -12.0464,
      "longitude": -77.0428,
      "status": "IN_TRANSIT",
      "timestamp": 1234567890
    }
  ],
  "Count": 1
}
```

### 7.3 Verificar Datos en DynamoDB

1. Ve a la consola de DynamoDB
2. Selecciona la tabla `dinex-tracking-dev`
3. Haz clic en **"Explore table items"**
4. Deberías ver el registro que acabas de crear

---

## Solución de Problemas Comunes

### Error: "Error: No valid credential sources found"

**Causa:** Credenciales AWS no configuradas correctamente.

**Solución:**
1. Verifica que ejecutaste `aws configure`
2. Verifica que el archivo `~/.aws/credentials` existe y contiene tus credenciales
3. Ejecuta `aws sts get-caller-identity` para verificar

### Error: "Error: error configuring Terraform AWS Provider: no EC2 IMDS role found"

**Causa:** Credenciales no válidas o incorrectas.

**Solución:**
1. Regenera tus Access Keys en la consola de AWS
2. Ejecuta `aws configure` nuevamente con las nuevas credenciales
3. Verifica con `aws sts get-caller-identity`

### Error: "Error: creating Lambda Function: InvalidParameterValueException: The role defined for the function cannot be assumed by Lambda"

**Causa:** El rol IAM no tiene permisos suficientes o no existe todavía.

**Solución:**
1. Espera 10-15 segundos y ejecuta `terraform apply` nuevamente
2. Verifica que el usuario IAM tiene la política `IAMFullAccess`

### Error: "Error: creating DynamoDB Table: ResourceInUseException: Table already exists"

**Causa:** Ya existe una tabla con el mismo nombre.

**Solución:**
1. Verifica si tienes recursos de un deployment anterior
2. Ejecuta `terraform destroy` para eliminar recursos anteriores
3. Ejecuta `terraform apply` nuevamente

### Error 403 al llamar al API

**Causa:** Problema con los permisos de API Gateway y Lambda.

**Solución:**
1. Verifica que el recurso `aws_lambda_permission.api_gateway_tracking` se creó correctamente
2. En la consola de Lambda, verifica que hay un trigger de API Gateway configurado
3. Ejecuta `terraform destroy` y `terraform apply` nuevamente

### Error: "Internal Server Error" (500) al llamar al API

**Causa:** Error en el código de la función Lambda.

**Solución:**
1. Ve a CloudWatch Logs:
   - https://console.aws.amazon.com/cloudwatch/
   - Haz clic en **"Logs"** → **"Log groups"**
   - Busca `/aws/lambda/dinex-tracking-dev`
   - Revisa los logs más recientes

2. Los logs mostrarán el error exacto en el código Python

### Costos inesperados

**Prevención:**
1. Configura AWS Budgets para recibir alertas:
   - Ve a: https://console.aws.amazon.com/billing/home#/budgets
   - Crea un presupuesto de $10/mes
   - Configura alertas al 80% y 100%

2. Monitorea regularmente:
   - https://console.aws.amazon.com/billing/home#/bills

3. **IMPORTANTE:** Al finalizar el proyecto, ejecuta:
   ```bash
   terraform destroy
   ```
   Para eliminar TODOS los recursos y evitar costos.

---

## Comandos Útiles del Makefile

El proyecto incluye un Makefile con comandos útiles:

```bash
# Ver todos los comandos disponibles
make help

# Validar configuración de Terraform
make validate

# Ver plan de ejecución
make plan

# Aplicar cambios
make apply

# Ver logs de Lambda
make logs

# Probar el API (health check)
make test-api

# Eliminar toda la infraestructura
make destroy
```

---

## Notas de Seguridad

### 🔐 Protección de Credenciales

1. **NUNCA subas credenciales a Git:**
   - Verifica que `.gitignore` incluye:
     ```
     *.tfvars
     .terraform/
     terraform.tfstate
     terraform.tfstate.backup
     .aws/
     ```

2. **Rota tus Access Keys regularmente:**
   - Cada 90 días es una buena práctica
   - En la consola IAM, puedes desactivar y crear nuevas keys

3. **Usa MFA (Multi-Factor Authentication):**
   - Configúralo en tu cuenta AWS root
   - También en el usuario IAM si es posible

4. **Principio de menor privilegio:**
   - El usuario `terraform-dinex` solo tiene los permisos necesarios
   - NO uses el usuario root para operaciones diarias

---

## Resumen de Archivos Modificados

Durante la corrección de errores, se modificaron los siguientes archivos:

1. **terraform/main.tf** (Líneas 193, 210, 267, 272)
   - Corregido: `lambda-simple` → `lambda`

2. **Makefile** (Líneas 5-6)
   - Corregido: `TF_DIR = terraform-simple` → `TF_DIR = terraform`
   - Corregido: `LAMBDA_DIR = lambda-simple` → `LAMBDA_DIR = lambda`

3. **lambda/tracking/deployment.zip** (Creado)
   - Empaquetado de la función Lambda tracking

4. **lambda/notifications/deployment.zip** (Creado)
   - Empaquetado de la función Lambda notifications

---

## Próximos Pasos

Después de completar esta guía, deberías:

1. ✅ Tener una cuenta de AWS activa
2. ✅ AWS CLI instalado y configurado
3. ✅ Terraform instalado
4. ✅ Credenciales AWS configuradas
5. ✅ Infraestructura desplegada en AWS
6. ✅ API funcionando y probado

**Siguiente paso sugerido:**
- Leer el archivo `EXPLICACION_PASO_A_PASO.md` para entender en detalle cómo funciona el código
- Practicar la presentación del proyecto usando `RESUMEN-PROYECTO-INDIVIDUAL.md`
- Preparar las respuestas a las preguntas del profesor (en `EXPLICACION_PASO_A_PASO.md`)

---

## Soporte y Recursos Adicionales

### Documentación Oficial:

- **Terraform AWS Provider:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **AWS Lambda:** https://docs.aws.amazon.com/lambda/
- **DynamoDB:** https://docs.aws.amazon.com/dynamodb/
- **API Gateway:** https://docs.aws.amazon.com/apigateway/

### Tutoriales:

- **Terraform Get Started:** https://learn.hashicorp.com/terraform
- **AWS Free Tier:** https://aws.amazon.com/free/
- **AWS Well-Architected Framework:** https://aws.amazon.com/architecture/well-architected/

---

**¡Éxito con tu proyecto!** 🚀
