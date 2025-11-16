"""
Función Lambda para Tracking de Paquetes
Sistema de Tracking DINEX Perú - Proyecto Individual

Esta función maneja:
- GET /tracking: Consultar estado de un paquete
- POST /tracking: Actualizar ubicación de un paquete
- GET /health: Health check del sistema

Autor: [Tu Nombre]
Curso: Infraestructura como Código
"""

import json
import boto3
import os
from datetime import datetime
import uuid
from decimal import Decimal

# Inicialización de clientes AWS
# Se ejecuta una vez cuando Lambda se inicia (warm start)
dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')

# Obtener variables de entorno configuradas en Terraform
TABLE_NAME = os.environ.get('TABLE_NAME')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')
SNS_TOPIC = os.environ.get('SNS_TOPIC')

# Referencia a la tabla DynamoDB
table = dynamodb.Table(TABLE_NAME)


class DecimalEncoder(json.JSONEncoder):
    """
    Encoder personalizado para convertir Decimal a float en JSON
    DynamoDB retorna números como Decimal, pero JSON no los soporta nativamente
    """
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)


def handler(event, context):
    """
    Handler principal de la función Lambda
    AWS Lambda invoca esta función para cada request

    Args:
        event: Diccionario con información del request (método HTTP, body, headers, etc.)
        context: Información del runtime de Lambda (request ID, tiempo restante, etc.)

    Returns:
        Diccionario con statusCode, headers y body (formato requerido por API Gateway)
    """

    # Log del evento recibido (útil para debugging)
    print(f"Evento recibido: {json.dumps(event)}")

    try:
        # Extraer información del request
        http_method = event.get('requestContext', {}).get('http', {}).get('method', 'GET')
        path = event.get('requestContext', {}).get('http', {}).get('path', '/')

        # Router: Dirigir a la función apropiada según el método HTTP y path
        if path.endswith('/health'):
            # Health check del sistema
            return health_check()

        elif http_method == 'GET':
            # Consultar tracking
            return get_tracking(event)

        elif http_method == 'POST':
            # Actualizar tracking
            return update_tracking(event)

        else:
            # Método no soportado
            return create_response(
                status_code=405,
                body={'error': 'Método no permitido',
                      'allowed_methods': ['GET', 'POST']}
            )

    except Exception as e:
        # Captura de errores globales
        # En producción, aquí se podría enviar el error a un servicio de monitoreo
        print(f"Error no manejado: {str(e)}")
        import traceback
        traceback.print_exc()

        return create_response(
            status_code=500,
            body={'error': 'Error interno del servidor',
                  'detail': str(e) if ENVIRONMENT == 'dev' else 'Internal Server Error'}
        )


def health_check():
    """
    Health check del sistema
    Verifica que Lambda y DynamoDB estén funcionando

    Returns:
        Response con estado del sistema
    """
    try:
        # Intentar leer información de la tabla (sin hacer query real)
        table_info = table.table_status

        return create_response(
            status_code=200,
            body={
                'status': 'healthy',
                'service': 'dinex-tracking',
                'environment': ENVIRONMENT,
                'timestamp': int(datetime.now().timestamp()),
                'dynamodb': 'connected',
                'table_status': table_info
            }
        )
    except Exception as e:
        return create_response(
            status_code=503,
            body={
                'status': 'unhealthy',
                'error': str(e)
            }
        )


def get_tracking(event):
    """
    Obtiene el estado actual de un paquete

    Query Parameters esperados:
        tracking_id: ID del tracking a consultar

    Returns:
        Response con información del tracking o error si no existe
    """

    # Extraer tracking_id de los query parameters
    # API Gateway v2 usa 'queryStringParameters'
    query_params = event.get('queryStringParameters') or {}
    tracking_id = query_params.get('tracking_id')

    # Validación: tracking_id es requerido
    if not tracking_id:
        return create_response(
            status_code=400,
            body={
                'error': 'Parámetro tracking_id es requerido',
                'example': '/tracking?tracking_id=TRK001'
            }
        )

    try:
        # Consultar DynamoDB por tracking_id
        # Query es más eficiente que Scan porque usa el partition key
        response = table.query(
            KeyConditionExpression='tracking_id = :tid',
            ExpressionAttributeValues={':tid': tracking_id},
            ScanIndexForward=False,  # Orden descendente (más reciente primero)
            Limit=1  # Solo necesitamos el registro más reciente
        )

        # Verificar si se encontró el tracking
        items = response.get('Items', [])
        if not items:
            return create_response(
                status_code=404,
                body={
                    'error': 'Tracking no encontrado',
                    'tracking_id': tracking_id
                }
            )

        # Obtener el primer item (más reciente)
        item = items[0]

        # Formatear respuesta con información relevante
        tracking_info = {
            'tracking_id': item['tracking_id'],
            'package_id': item.get('package_id', 'N/A'),
            'status': item.get('status', 'UNKNOWN'),
            'location': item.get('location', 'Ubicación desconocida'),
            'latitude': item.get('latitude'),
            'longitude': item.get('longitude'),
            'last_update': item.get('timestamp'),
            'last_update_human': datetime.fromtimestamp(
                int(item.get('timestamp', 0))
            ).strftime('%Y-%m-%d %H:%M:%S') if item.get('timestamp') else 'N/A',
            'notes': item.get('notes', ''),
            'estimated_delivery': item.get('estimated_delivery', 'No especificado')
        }

        return create_response(
            status_code=200,
            body=tracking_info,
            use_decimal_encoder=True
        )

    except Exception as e:
        # Error al consultar DynamoDB
        print(f"Error consultando DynamoDB: {str(e)}")
        return create_response(
            status_code=500,
            body={
                'error': 'Error consultando el tracking',
                'detail': str(e) if ENVIRONMENT == 'dev' else 'Database error'
            }
        )


def update_tracking(event):
    """
    Actualiza la ubicación y estado de un paquete

    Body esperado (JSON):
        {
            "tracking_id": "TRK001",
            "package_id": "PKG001",  (opcional)
            "location": "Lima - Centro de Distribución",
            "latitude": -12.0464,  (opcional)
            "longitude": -77.0428,  (opcional)
            "status": "IN_TRANSIT",  (opcional)
            "notes": "Paquete en ruta",  (opcional)
            "estimated_delivery": "2024-12-25"  (opcional)
        }

    Returns:
        Response confirmando la actualización o error si falla
    """

    try:
        # Parsear el body del request
        body = event.get('body', '{}')

        # Si body viene como string, parsearlo a JSON
        if isinstance(body, str):
            body = json.loads(body)

        # Validar campos requeridos
        tracking_id = body.get('tracking_id')
        location = body.get('location')

        if not tracking_id:
            return create_response(
                status_code=400,
                body={'error': 'tracking_id es requerido'}
            )

        if not location:
            return create_response(
                status_code=400,
                body={'error': 'location es requerido'}
            )

        # Generar timestamp actual
        timestamp = int(datetime.now().timestamp())

        # Generar package_id si no viene en el request
        package_id = body.get('package_id', f"PKG-{uuid.uuid4().hex[:8].upper()}")

        # Construir el item para DynamoDB
        item = {
            # Keys (partition + sort)
            'tracking_id': tracking_id,
            'timestamp': timestamp,

            # Atributos
            'package_id': package_id,
            'location': location,
            'status': body.get('status', 'IN_TRANSIT'),

            # Coordenadas GPS (opcional)
            'latitude': Decimal(str(body['latitude'])) if body.get('latitude') else None,
            'longitude': Decimal(str(body['longitude'])) if body.get('longitude') else None,

            # Información adicional
            'notes': body.get('notes', ''),
            'estimated_delivery': body.get('estimated_delivery'),

            # TTL: Eliminar automáticamente después de 30 días
            'expiry': timestamp + (30 * 24 * 60 * 60),

            # Metadata
            'environment': ENVIRONMENT,
            'updated_by': 'system'
        }

        # Remover campos None (DynamoDB no acepta null)
        item = {k: v for k, v in item.items() if v is not None}

        # Guardar en DynamoDB
        table.put_item(Item=item)

        # Log de éxito
        print(f"Tracking actualizado exitosamente: {tracking_id}")

        # Enviar notificación (opcional, si SNS está configurado)
        if SNS_TOPIC and body.get('notify', True):
            try:
                send_notification(tracking_id, location, body.get('status', 'IN_TRANSIT'))
            except Exception as e:
                # Si falla la notificación, no afecta la actualización
                print(f"Error enviando notificación: {str(e)}")

        # Retornar confirmación
        return create_response(
            status_code=201,
            body={
                'message': 'Tracking actualizado exitosamente',
                'tracking_id': tracking_id,
                'package_id': package_id,
                'timestamp': timestamp,
                'location': location,
                'status': item['status']
            }
        )

    except json.JSONDecodeError:
        # Error al parsear JSON
        return create_response(
            status_code=400,
            body={'error': 'Body inválido, debe ser JSON válido'}
        )

    except Exception as e:
        # Error general
        print(f"Error actualizando tracking: {str(e)}")
        return create_response(
            status_code=500,
            body={
                'error': 'Error actualizando el tracking',
                'detail': str(e) if ENVIRONMENT == 'dev' else 'Update error'
            }
        )


def send_notification(tracking_id, location, status):
    """
    Envía notificación via SNS cuando se actualiza un tracking

    Args:
        tracking_id: ID del tracking
        location: Nueva ubicación
        status: Estado actual
    """
    try:
        message = f"""
Actualización de Tracking - DINEX

Tracking ID: {tracking_id}
Estado: {status}
Ubicación: {location}
Fecha/Hora: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

Sistema de Tracking DINEX Perú
        """

        sns.publish(
            TopicArn=SNS_TOPIC,
            Subject=f"Tracking {tracking_id} - {status}",
            Message=message
        )

        print(f"Notificación enviada para tracking {tracking_id}")

    except Exception as e:
        # Log del error pero no falla la función
        print(f"Error enviando notificación SNS: {str(e)}")


def create_response(status_code, body, use_decimal_encoder=False):
    """
    Crea una respuesta HTTP en el formato requerido por API Gateway

    Args:
        status_code: Código HTTP (200, 400, 500, etc.)
        body: Diccionario con el contenido de la respuesta
        use_decimal_encoder: Si usar el encoder para Decimal

    Returns:
        Diccionario con formato de respuesta de API Gateway
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',  # CORS
            'Access-Control-Allow-Headers': 'Content-Type,X-Api-Key',
            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
            'X-Environment': ENVIRONMENT
        },
        'body': json.dumps(body, cls=DecimalEncoder if use_decimal_encoder else None, ensure_ascii=False)
    }


# Para testing local (no se ejecuta en Lambda)
if __name__ == '__main__':
    # Evento de prueba: GET
    test_event_get = {
        'requestContext': {
            'http': {
                'method': 'GET',
                'path': '/tracking'
            }
        },
        'queryStringParameters': {
            'tracking_id': 'TRK001'
        }
    }

    # Evento de prueba: POST
    test_event_post = {
        'requestContext': {
            'http': {
                'method': 'POST',
                'path': '/tracking'
            }
        },
        'body': json.dumps({
            'tracking_id': 'TRK001',
            'package_id': 'PKG001',
            'location': 'Lima - Centro de Distribución',
            'latitude': -12.0464,
            'longitude': -77.0428,
            'status': 'IN_TRANSIT',
            'notes': 'Paquete en tránsito'
        })
    }

    print("=== Test GET ===")
    # Descomentar para probar localmente
    # print(json.dumps(handler(test_event_get, None), indent=2))

    print("\n=== Test POST ===")
    # print(json.dumps(handler(test_event_post, None), indent=2))
