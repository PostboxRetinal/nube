from flask import Blueprint, request, jsonify
from orders.models.order_model import Orders, OrderItems
from db.db import db
from exceptions import BadRequestError, ProductNotFoundError, InsufficientInventoryError, InternalServerError
import requests
import os
import uuid
from datetime import datetime

order_controller = Blueprint('order_controller', __name__)

def get_products_service_url():
    PORT_CONSUL = os.environ["PORT_CONSUL"]
    try:
        response = requests.get(f'http://consul:{PORT_CONSUL}/v1/catalog/service/products')
        if response.status_code == 200:
            services = response.json()
            if services:
                service = services[0]
                address = service.get('ServiceAddress') or service.get('Address')
                port = service.get('ServicePort')
                return f"http://{address}:{port}"
    except Exception as e:
        print(f"Error consultando a Consul para products: {e}")
    return None

def get_users_service_url():
    PORT_CONSUL = os.environ["PORT_CONSUL"]
    try:
        response = requests.get(f'http://consul:{PORT_CONSUL}/v1/catalog/service/users')
        if response.status_code == 200:
            services = response.json()
            if services:
                service = services[0]
                address = service.get('ServiceAddress') or service.get('Address')
                port = service.get('ServicePort')
                return f"http://{address}:{port}"
    except Exception as e:
        print(f"Error consultando a Consul para users: {e}")
    return None

@order_controller.route('/api/orders', methods=['GET'])
def get_orders():
    orders = Orders.query.all()
    users_url = get_users_service_url()
    products_url = get_products_service_url()

    product_name_cache = {}

    def get_product_name(product_id):
        if product_id in product_name_cache:
            return product_name_cache[product_id]
        name = f"ID: {product_id}"
        if products_url:
            try:
                resp = requests.get(f"{products_url}/api/products/{product_id}", timeout=3)
                if resp.status_code == 200:
                    name = resp.json().get('name', name)
            except requests.exceptions.RequestException:
                pass
        product_name_cache[product_id] = name
        return name

    result = []
    for o in orders:
        user_name = f"ID: {o.user_id}"
        if users_url:
            try:
                user_resp = requests.get(f"{users_url}/api/users/{o.user_id}", timeout=3)
                if user_resp.status_code == 200:
                    user_name = user_resp.json().get('name', user_name)
            except requests.exceptions.RequestException as e:
                print(f"Error conectando con Users para el ID {o.user_id}: {e}")

        result.append({
            'id': o.id,
            'user': user_name,
            'total': float(o.total),
            'created_at': o.created_at.strftime('%Y-%m-%d %H:%M'),
            'items': [
                {
                    'product_id': item.product_id,
                    'product_name': get_product_name(item.product_id),  # ← new
                    'quantity': item.quantity,
                    'subtotal': float(item.subtotal)
                }
                for item in o.items
            ]
        })

    return jsonify(result)

@order_controller.route('/api/orders', methods=['POST'])
def create_order():
    data = request.get_json()
    products = data.get('products') if data else None
    user_id = data.get('user_id') if data else None

    if not products or not isinstance(products, list):
        raise BadRequestError("Falta la información de los productos.")

    if not user_id:
        raise BadRequestError("Debe seleccionar un usuario.")

    products_url = get_products_service_url()
    if not products_url:
        raise InternalServerError("Servicio de productos no disponible en Consul.")

    productos_validados = []

    for item in products:
        prod_id = item.get('id')
        qty = item.get('quantity')

        if prod_id is None or qty is None:
            raise BadRequestError("Cada producto debe incluir 'id' y 'quantity'.")

        try:
            prod_resp = requests.get(f"{products_url}/api/products/{prod_id}", timeout=5)
        except requests.exceptions.RequestException:
            raise InternalServerError("Error de conexión con servicio de productos.")

        if prod_resp.status_code == 404:
            raise ProductNotFoundError(product_id=prod_id)
        elif prod_resp.status_code != 200:
            raise InternalServerError("Error al consultar producto.")

        prod_data = prod_resp.json()

        if prod_data['stock'] < qty:
            raise InsufficientInventoryError(
                product_id=prod_id,
                available=prod_data['stock'],
                requested=qty,
            )

        productos_validados.append({
            'id': prod_id,
            'qty': qty,
            'current_stock': prod_data['stock'],
            'price': prod_data['price']
        })

    try:
        order_id = str(uuid.uuid4())
        order_total = sum(p['price'] * p['qty'] for p in productos_validados)

        new_order = Orders(
            id=order_id,
            user_id=user_id,
            total=order_total,
            created_at=datetime.utcnow()
        )
        db.session.add(new_order)

        for prod in productos_validados:
            new_stock = prod['current_stock'] - prod['qty']
            subtotal = prod['price'] * prod['qty']

            update_resp = requests.put(
                f"{products_url}/api/products/{prod['id']}",
                json={'stock': new_stock},
                timeout=5
            )
            if update_resp.status_code not in [200, 204]:
                raise InternalServerError("Error al actualizar el inventario.")

            db.session.add(OrderItems(
                order_id=order_id,
                product_id=prod['id'],
                quantity=prod['qty'],
                subtotal=subtotal
            ))

        db.session.commit()
        return jsonify({'message': 'Orden creada exitosamente', 'order_id': order_id}), 201

    except Exception:
        db.session.rollback()
        raise

@order_controller.route('/api/orders/<string:order_id>', methods=['DELETE'])
def delete_order(order_id):
    order = Orders.query.get_or_404(order_id)
    db.session.delete(order)
    db.session.commit()
    return jsonify({'message': 'Order deleted successfully'})