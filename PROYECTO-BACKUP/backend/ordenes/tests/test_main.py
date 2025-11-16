"""
Tests unitarios para la función Lambda de Órdenes
"""

import json
import pytest
import sys
import os

# Configurar path para importar el módulo
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

# Mock de variables de entorno
os.environ['ORDERS_TABLE'] = 'test-orders-table'
os.environ['NOTIFICATIONS_QUEUE'] = 'https://sqs.us-east-1.amazonaws.com/123456789/test-queue'
os.environ['ENVIRONMENT'] = 'test'

# Importar después de configurar env vars
import main


class TestOrdersLambda:
    """Tests para la función Lambda de órdenes"""

    def test_create_order_success(self, monkeypatch):
        """Test: Crear orden exitosamente"""

        # Mock de DynamoDB put_item
        def mock_put_item(**kwargs):
            return {}

        # Mock de SQS send_message
        def mock_send_message(**kwargs):
            return {'MessageId': '123'}

        monkeypatch.setattr('main.orders_table.put_item', mock_put_item)
        monkeypatch.setattr('main.sqs.send_message', mock_send_message)

        # Evento de prueba
        event = {
            'httpMethod': 'POST',
            'body': json.dumps({
                'customer_id': 'CUST001',
                'products': [
                    {'sku': 'PROD123', 'quantity': 2, 'price': 50.00}
                ],
                'delivery_address': 'Av. Javier Prado 123, Lima'
            })
        }

        # Ejecutar handler
        response = main.handler(event, None)

        # Verificar respuesta
        assert response['statusCode'] == 201
        body = json.loads(response['body'])
        assert 'order_id' in body
        assert body['status'] == 'PENDING'
        assert body['total'] == 100.0

    def test_create_order_missing_customer(self):
        """Test: Error cuando falta customer_id"""

        event = {
            'httpMethod': 'POST',
            'body': json.dumps({
                'products': [{'sku': 'PROD123', 'quantity': 1}]
            })
        }

        response = main.handler(event, None)

        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert 'error' in body

    def test_create_order_invalid_json(self):
        """Test: Error con JSON inválido"""

        event = {
            'httpMethod': 'POST',
            'body': 'invalid json'
        }

        response = main.handler(event, None)

        assert response['statusCode'] == 400

    def test_get_orders_success(self, monkeypatch):
        """Test: Obtener lista de órdenes"""

        # Mock de DynamoDB scan
        def mock_scan(**kwargs):
            return {
                'Items': [
                    {
                        'order_id': 'ORD-123',
                        'customer_id': 'CUST001',
                        'status': 'PENDING',
                        'total': 100.00
                    }
                ]
            }

        monkeypatch.setattr('main.orders_table.scan', mock_scan)

        event = {
            'httpMethod': 'GET',
            'queryStringParameters': None
        }

        response = main.handler(event, None)

        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert 'orders' in body
        assert len(body['orders']) == 1

    def test_method_not_allowed(self):
        """Test: Método HTTP no permitido"""

        event = {
            'httpMethod': 'DELETE'
        }

        response = main.handler(event, None)

        assert response['statusCode'] == 405


# Para ejecutar tests:
# pytest tests/test_main.py -v
if __name__ == '__main__':
    pytest.main([__file__, '-v'])
