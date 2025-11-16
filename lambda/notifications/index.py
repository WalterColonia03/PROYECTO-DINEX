"""
Función Lambda para Notificaciones
Sistema de Tracking DINEX Perú - Proyecto Individual

Esta función se activa automáticamente cuando hay cambios en DynamoDB
y envía notificaciones via SNS

Autor: [Tu Nombre]
Curso: Infraestructura como Código
"""

import json
import boto3
import os
from datetime import datetime

# Cliente SNS para enviar notificaciones
sns = boto3.client('sns')

# Variables de entorno
SNS_TOPIC = os.environ.get('SNS_TOPIC')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')


def handler(event, context):
    """
    Handler principal para procesamiento de notificaciones

    Esta función puede ser invocada de dos formas:
    1. Manualmente via API (no implementado en este proyecto simple)
    2. Automáticamente via DynamoDB Stream (futuro)

    Args:
        event: Evento con información del cambio en DynamoDB
        context: Contexto del runtime de Lambda

    Returns:
        Response con resultado del procesamiento
    """

    print(f"Evento de notificación recibido: {json.dumps(event)}")

    try:
        # Por ahora, esta función es un placeholder
        # En una implementación completa, procesaría DynamoDB Stream events

        # Contar records procesados
        records_count = len(event.get('Records', []))

        if records_count > 0:
            # Procesar cada record
            for record in event['Records']:
                process_notification_record(record)

            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': f'{records_count} notificaciones procesadas',
                    'environment': ENVIRONMENT
                })
            }
        else:
            # No hay records para procesar
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'No hay notificaciones pendientes',
                    'environment': ENVIRONMENT
                })
            }

    except Exception as e:
        print(f"Error procesando notificaciones: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Error procesando notificaciones',
                'detail': str(e) if ENVIRONMENT == 'dev' else 'Processing error'
            })
        }


def process_notification_record(record):
    """
    Procesa un record individual de DynamoDB Stream

    Args:
        record: Record de DynamoDB Stream con información del cambio
    """

    try:
        # Tipo de evento: INSERT, MODIFY, REMOVE
        event_name = record.get('eventName')

        print(f"Procesando evento: {event_name}")

        # En una implementación completa, aquí se procesaría el evento
        # y se enviaría la notificación correspondiente

        # Ejemplo: Si es INSERT o MODIFY, enviar notificación
        if event_name in ['INSERT', 'MODIFY']:
            # Extraer nueva imagen (nuevo estado del item)
            new_image = record.get('dynamodb', {}).get('NewImage', {})

            # Convertir formato DynamoDB a dict normal
            tracking_id = new_image.get('tracking_id', {}).get('S', 'UNKNOWN')
            location = new_image.get('location', {}).get('S', 'Unknown')
            status = new_image.get('status', {}).get('S', 'UNKNOWN')

            # Enviar notificación
            send_tracking_notification(tracking_id, location, status)

    except Exception as e:
        print(f"Error procesando record: {str(e)}")
        # En producción, podríamos enviar a DLQ (Dead Letter Queue)


def send_tracking_notification(tracking_id, location, status):
    """
    Envía notificación SNS sobre actualización de tracking

    Args:
        tracking_id: ID del tracking
        location: Ubicación actual
        status: Estado actual
    """

    try:
        # Construir mensaje de notificación
        message = f"""
Actualización de Tracking - DINEX

Tracking ID: {tracking_id}
Estado: {status}
Ubicación: {location}
Fecha/Hora: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

Este es un mensaje automático del Sistema de Tracking DINEX.
        """

        subject = f"DINEX - Tracking {tracking_id}: {status}"

        # Publicar a SNS Topic
        if SNS_TOPIC:
            response = sns.publish(
                TopicArn=SNS_TOPIC,
                Subject=subject,
                Message=message
            )

            print(f"Notificación enviada: MessageId={response.get('MessageId')}")
        else:
            print("SNS_TOPIC no configurado, saltando envío de notificación")

    except Exception as e:
        print(f"Error enviando notificación SNS: {str(e)}")
        # No fallar la función si la notificación falla


# Testing local
if __name__ == '__main__':
    # Evento de prueba simulando DynamoDB Stream
    test_event = {
        'Records': [
            {
                'eventName': 'INSERT',
                'dynamodb': {
                    'NewImage': {
                        'tracking_id': {'S': 'TRK001'},
                        'location': {'S': 'Lima - Centro de Distribución'},
                        'status': {'S': 'IN_TRANSIT'},
                        'timestamp': {'N': '1699999999'}
                    }
                }
            }
        ]
    }

    print("=== Test Notifications ===")
    # Descomentar para probar localmente
    # print(json.dumps(handler(test_event, None), indent=2))
