"""
Lambda Function: Procesar Órdenes
Maneja la creación y consulta de órdenes de clientes
"""

import json
import os
import boto3
from datetime import datetime, timedelta
from decimal import Decimal
import uuid
import logging

# Configuración de logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# Clientes AWS
dynamodb = boto3.resource('dynamodb')
sqs = boto3.client('sqs')

# Variables de entorno
ORDERS_TABLE = os.environ.get('ORDERS_TABLE')
NOTIFICATIONS_QUEUE = os.environ.get('NOTIFICATIONS_QUEUE')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')

# Tabla DynamoDB
orders_table = dynamodb.Table(ORDERS_TABLE)


class DecimalEncoder(json.JSONEncoder):
    """Encoder para convertir Decimal a JSON"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)


def handler(event, context):
    """
    Handler principal de la función Lambda

    Soporta:
    - POST /orders: Crear nueva orden
    - GET /orders: Listar órdenes
    - GET /orders?customer_id=XXX: Listar órdenes por cliente
    """

    logger.info(f"Evento recibido: {json.dumps(event)}")

    try:
        # Determinar método HTTP
        http_method = event.get('httpMethod', 'GET')

        if http_method == 'POST':
            return create_order(event)
        elif http_method == 'GET':
            return get_orders(event)
        else:
            return response(405, {'error': 'Método no permitido'})

    except Exception as e:
        logger.error(f"Error procesando solicitud: {str(e)}", exc_info=True)
        return response(500, {'error': 'Error interno del servidor', 'detail': str(e)})


def create_order(event):
    """Crear nueva orden"""

    try:
        # Parsear body
        body = json.loads(event.get('body', '{}'))

        # Validar campos requeridos
        if not body.get('customer_id'):
            return response(400, {'error': 'customer_id es requerido'})

        if not body.get('products') or len(body['products']) == 0:
            return response(400, {'error': 'products es requerido y debe contener al menos un producto'})

        # Generar ID de orden
        order_id = f"ORD-{str(uuid.uuid4())[:8].upper()}"
        timestamp = datetime.utcnow().isoformat()

        # Calcular total
        total = sum(
            product.get('quantity', 1) * product.get('price', 0)
            for product in body['products']
        )

        # Calcular TTL (30 días desde ahora)
        ttl = int((datetime.utcnow() + timedelta(days=30)).timestamp())

        # Crear orden
        order = {
            'order_id': order_id,
            'created_at': timestamp,
            'customer_id': body['customer_id'],
            'products': body['products'],
            'delivery_address': body.get('delivery_address', ''),
            'status': 'PENDING',
            'total': Decimal(str(total)),
            'ttl': ttl,
            'environment': ENVIRONMENT
        }

        # Guardar en DynamoDB
        orders_table.put_item(Item=order)

        logger.info(f"Orden creada exitosamente: {order_id}")

        # Enviar notificación a SQS
        try:
            send_notification({
                'type': 'ORDER_CREATED',
                'order_id': order_id,
                'customer_id': body['customer_id'],
                'total': float(total)
            })
        except Exception as e:
            logger.warning(f"No se pudo enviar notificación: {str(e)}")

        return response(201, {
            'message': 'Orden creada exitosamente',
            'order_id': order_id,
            'status': 'PENDING',
            'total': float(total)
        })

    except json.JSONDecodeError:
        return response(400, {'error': 'JSON inválido'})
    except Exception as e:
        logger.error(f"Error creando orden: {str(e)}", exc_info=True)
        return response(500, {'error': 'Error creando orden', 'detail': str(e)})


def get_orders(event):
    """Obtener órdenes"""

    try:
        # Parámetros de query
        params = event.get('queryStringParameters') or {}
        customer_id = params.get('customer_id')

        if customer_id:
            # Consultar por cliente usando GSI
            result = orders_table.query(
                IndexName='customer_index',
                KeyConditionExpression='customer_id = :cid',
                ExpressionAttributeValues={
                    ':cid': customer_id
                },
                Limit=50,
                ScanIndexForward=False  # Ordenar por fecha descendente
            )
        else:
            # Scan (no recomendado en producción para tablas grandes)
            result = orders_table.scan(Limit=50)

        orders = result.get('Items', [])

        logger.info(f"Se encontraron {len(orders)} órdenes")

        return response(200, {
            'orders': orders,
            'count': len(orders)
        }, use_decimal_encoder=True)

    except Exception as e:
        logger.error(f"Error obteniendo órdenes: {str(e)}", exc_info=True)
        return response(500, {'error': 'Error obteniendo órdenes', 'detail': str(e)})


def send_notification(message):
    """Enviar notificación a SQS"""

    if not NOTIFICATIONS_QUEUE:
        logger.warning("NOTIFICATIONS_QUEUE no configurada")
        return

    try:
        sqs.send_message(
            QueueUrl=NOTIFICATIONS_QUEUE,
            MessageBody=json.dumps(message)
        )
        logger.info(f"Notificación enviada: {message['type']}")
    except Exception as e:
        logger.error(f"Error enviando notificación: {str(e)}")
        raise


def response(status_code, body, use_decimal_encoder=False):
    """Generar respuesta HTTP"""

    encoder = DecimalEncoder if use_decimal_encoder else None

    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
        },
        'body': json.dumps(body, cls=encoder)
    }


# Para testing local
if __name__ == '__main__':
    # Evento de prueba
    test_event = {
        'httpMethod': 'POST',
        'body': json.dumps({
            'customer_id': 'CUST001',
            'products': [
                {'sku': 'PROD123', 'quantity': 2, 'price': 50.00}
            ],
            'delivery_address': 'Av. Javier Prado 123, Lima'
        })
    }

    result = handler(test_event, None)
    print(json.dumps(result, indent=2))
