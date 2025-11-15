"""
Lambda Function: Optimización de Rutas
Optimiza rutas de entrega usando algoritmos simples
"""

import json
import os
import boto3
from datetime import datetime
import uuid
import logging
import math

logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

dynamodb = boto3.resource('dynamodb')

ROUTES_TABLE = os.environ.get('ROUTES_TABLE')
ORDERS_TABLE = os.environ.get('ORDERS_TABLE')

routes_table = dynamodb.Table(ROUTES_TABLE)
orders_table = dynamodb.Table(ORDERS_TABLE)


def handler(event, context):
    """Handler principal para optimización de rutas"""

    logger.info(f"Evento recibido: {json.dumps(event)}")

    try:
        body = json.loads(event.get('body', '{}'))

        order_ids = body.get('order_ids', [])
        driver_id = body.get('driver_id')

        if not order_ids or not driver_id:
            return response(400, {'error': 'order_ids y driver_id son requeridos'})

        # Obtener órdenes
        orders = get_orders(order_ids)

        if not orders:
            return response(404, {'error': 'No se encontraron órdenes'})

        # Optimizar ruta (algoritmo simple: nearest neighbor)
        optimized_route = optimize_route(orders)

        # Calcular distancia total estimada
        total_distance = calculate_total_distance(optimized_route)

        # Crear ruta
        route_id = f"ROUTE-{str(uuid.uuid4())[:8].upper()}"
        timestamp = datetime.utcnow().isoformat()

        route = {
            'route_id': route_id,
            'driver_id': driver_id,
            'created_at': timestamp,
            'order_ids': [order['order_id'] for order in optimized_route],
            'stops': len(optimized_route),
            'estimated_distance_km': round(total_distance, 2),
            'status': 'PLANNED'
        }

        # Guardar ruta
        routes_table.put_item(Item=route)

        logger.info(f"Ruta optimizada creada: {route_id}")

        return response(200, {
            'message': 'Ruta optimizada exitosamente',
            'route_id': route_id,
            'stops': len(optimized_route),
            'estimated_distance_km': round(total_distance, 2),
            'order_sequence': [order['order_id'] for order in optimized_route]
        })

    except json.JSONDecodeError:
        return response(400, {'error': 'JSON inválido'})
    except Exception as e:
        logger.error(f"Error optimizando ruta: {str(e)}", exc_info=True)
        return response(500, {'error': 'Error optimizando ruta', 'detail': str(e)})


def get_orders(order_ids):
    """Obtener órdenes desde DynamoDB"""
    orders = []

    for order_id in order_ids:
        try:
            result = orders_table.query(
                KeyConditionExpression='order_id = :oid',
                ExpressionAttributeValues={':oid': order_id},
                Limit=1
            )
            if result.get('Items'):
                orders.append(result['Items'][0])
        except Exception as e:
            logger.warning(f"Error obteniendo orden {order_id}: {str(e)}")

    return orders


def optimize_route(orders):
    """
    Optimizar ruta usando algoritmo Nearest Neighbor (simplificado)
    En producción, usar algoritmos más sofisticados como:
    - Algoritmo genético
    - Simulated Annealing
    - Google Maps Optimization API
    """

    if not orders:
        return []

    # Para este ejemplo, simplemente ordenamos por proximidad geográfica simulada
    # En producción, usar coordenadas reales y calcular distancias reales

    # Asignar coordenadas simuladas basadas en la dirección (hash simple)
    for order in orders:
        address = order.get('delivery_address', '')
        # Simulación: usar hash de la dirección para generar coordenadas
        hash_val = hash(address)
        order['_lat'] = (hash_val % 180) - 90  # Latitud simulada
        order['_lng'] = (hash_val % 360) - 180  # Longitud simulada

    # Algoritmo Nearest Neighbor simple
    optimized = []
    remaining = orders.copy()
    current = remaining.pop(0)  # Empezar con la primera orden
    optimized.append(current)

    while remaining:
        # Encontrar la orden más cercana
        nearest = min(remaining, key=lambda o: euclidean_distance(
            current['_lat'], current['_lng'],
            o['_lat'], o['_lng']
        ))
        optimized.append(nearest)
        remaining.remove(nearest)
        current = nearest

    return optimized


def euclidean_distance(lat1, lng1, lat2, lng2):
    """Calcular distancia euclidiana simple (para demostración)"""
    return math.sqrt((lat2 - lat1)**2 + (lng2 - lng1)**2)


def calculate_total_distance(route):
    """Calcular distancia total de la ruta"""
    if len(route) < 2:
        return 0

    total = 0
    for i in range(len(route) - 1):
        dist = euclidean_distance(
            route[i]['_lat'], route[i]['_lng'],
            route[i+1]['_lat'], route[i+1]['_lng']
        )
        total += dist

    # Convertir a km (factor arbitrario para simulación)
    return total * 10


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
