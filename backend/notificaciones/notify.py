"""
Lambda Function: Notificaciones
Procesa mensajes desde SQS y envía notificaciones a clientes
"""

import json
import os
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')


def handler(event, context):
    """
    Handler para procesar mensajes de SQS

    Recibe:
    - Eventos de creación de órdenes
    - Actualizaciones de tracking
    - Alertas del sistema
    """

    logger.info(f"Evento recibido: {json.dumps(event)}")

    try:
        # Procesar mensajes de SQS
        records = event.get('Records', [])

        for record in records:
            process_notification(record)

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'{len(records)} notificaciones procesadas'
            })
        }

    except Exception as e:
        logger.error(f"Error procesando notificaciones: {str(e)}", exc_info=True)
        # En caso de error, el mensaje volverá a la cola
        raise


def process_notification(record):
    """Procesar una notificación individual"""

    try:
        # Parsear mensaje
        message_body = json.loads(record['body'])
        notification_type = message_body.get('type', 'UNKNOWN')

        logger.info(f"Procesando notificación tipo: {notification_type}")

        # Aquí iría la lógica para enviar notificaciones reales
        # Por ejemplo: Email con SES, SMS con SNS, Push notifications, etc.

        if notification_type == 'ORDER_CREATED':
            send_order_confirmation(message_body)
        elif notification_type == 'TRACKING_UPDATE':
            send_tracking_update(message_body)
        else:
            logger.warning(f"Tipo de notificación desconocido: {notification_type}")

        logger.info(f"Notificación procesada exitosamente: {notification_type}")

    except json.JSONDecodeError as e:
        logger.error(f"Error parseando mensaje: {str(e)}")
        raise
    except Exception as e:
        logger.error(f"Error procesando notificación: {str(e)}")
        raise


def send_order_confirmation(message):
    """Enviar confirmación de orden creada"""

    order_id = message.get('order_id')
    customer_id = message.get('customer_id')
    total = message.get('total', 0)

    # Simulación de envío de notificación
    logger.info(f"📧 Enviando confirmación de orden a cliente {customer_id}")
    logger.info(f"   Orden: {order_id}")
    logger.info(f"   Total: ${total:.2f}")

    # En producción, usar AWS SES para enviar email:
    # ses = boto3.client('ses')
    # ses.send_email(...)

    # O SNS para SMS:
    # sns = boto3.client('sns')
    # sns.publish(PhoneNumber=customer_phone, Message=message)

    return True


def send_tracking_update(message):
    """Enviar actualización de tracking"""

    order_id = message.get('order_id')
    status = message.get('status')
    location = message.get('location', 'Sin ubicación')

    logger.info(f"📍 Enviando actualización de tracking")
    logger.info(f"   Orden: {order_id}")
    logger.info(f"   Estado: {status}")
    logger.info(f"   Ubicación: {location}")

    # Aquí iría la lógica real de notificación

    return True


# Para testing local
if __name__ == '__main__':
    # Simular evento SQS
    test_event = {
        'Records': [
            {
                'body': json.dumps({
                    'type': 'ORDER_CREATED',
                    'order_id': 'ORD-TEST123',
                    'customer_id': 'CUST001',
                    'total': 150.00
                })
            }
        ]
    }

    result = handler(test_event, None)
    print(json.dumps(result, indent=2))
