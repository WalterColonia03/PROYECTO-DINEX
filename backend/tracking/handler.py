"""
Lambda Function: Tracking
Actualiza y consulta el estado de tracking de órdenes
"""

import json
import os
import boto3
from datetime import datetime
import uuid
import logging

logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

dynamodb = boto3.resource('dynamodb')

TRACKING_TABLE = os.environ.get('TRACKING_TABLE')
ORDERS_TABLE = os.environ.get('ORDERS_TABLE')

tracking_table = dynamodb.Table(TRACKING_TABLE)
orders_table = dynamodb.Table(ORDERS_TABLE)


def handler(event, context):
    """Handler principal"""

    logger.info(f"Evento recibido: {json.dumps(event)}")

    try:
        http_method = event.get('httpMethod', 'GET')

        if http_method == 'GET':
            return get_tracking(event)
        elif http_method == 'PUT':
            return update_tracking(event)
        else:
            return response(405, {'error': 'Método no permitido'})

    except Exception as e:
        logger.error(f"Error: {str(e)}", exc_info=True)
        return response(500, {'error': 'Error interno', 'detail': str(e)})


def get_tracking(event):
    """Consultar tracking de una orden"""

    params = event.get('queryStringParameters') or {}
    order_id = params.get('order_id')

    if not order_id:
        return response(400, {'error': 'order_id es requerido'})

    try:
        # Consultar tracking events
        result = tracking_table.query(
            IndexName='order_index',
            KeyConditionExpression='order_id = :oid',
            ExpressionAttributeValues={':oid': order_id},
            ScanIndexForward=False  # Más reciente primero
        )

        events = result.get('Items', [])

        return response(200, {
            'order_id': order_id,
            'events': events,
            'count': len(events)
        })

    except Exception as e:
        logger.error(f"Error obteniendo tracking: {str(e)}")
        return response(500, {'error': 'Error obteniendo tracking'})


def update_tracking(event):
    """Actualizar tracking de una orden"""

    try:
        body = json.loads(event.get('body', '{}'))

        order_id = body.get('order_id')
        status = body.get('status')
        location = body.get('location', '')

        if not order_id or not status:
            return response(400, {'error': 'order_id y status son requeridos'})

        # Crear tracking event
        tracking_id = f"TRK-{str(uuid.uuid4())[:8].upper()}"
        timestamp = datetime.utcnow().isoformat()

        tracking_event = {
            'tracking_id': tracking_id,
            'timestamp': timestamp,
            'order_id': order_id,
            'status': status,
            'location': location
        }

        tracking_table.put_item(Item=tracking_event)

        # Actualizar estado de la orden
        try:
            orders_table.update_item(
                Key={'order_id': order_id, 'created_at': body.get('created_at', '')},
                UpdateExpression='SET #status = :status',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={':status': status}
            )
        except Exception as e:
            logger.warning(f"No se pudo actualizar orden: {str(e)}")

        logger.info(f"Tracking actualizado: {tracking_id}")

        return response(200, {
            'message': 'Tracking actualizado',
            'tracking_id': tracking_id,
            'status': status
        })

    except json.JSONDecodeError:
        return response(400, {'error': 'JSON inválido'})
    except Exception as e:
        logger.error(f"Error actualizando tracking: {str(e)}")
        return response(500, {'error': 'Error actualizando tracking'})


def response(status_code, body):
    """Generar respuesta HTTP"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body)
    }
