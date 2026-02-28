from flask import Blueprint, request, jsonify, session
from orders.models.order_model import Orders
from db.db import db
import requests 
import os

order_controller = Blueprint('order_controller', __name__)

# Descubrimiento de microservicios mediante Consul
def get_products_service_url():
    PORT_CONSUL = os.environ["PORT_CONSUL"]
    try:
        response = requests.get('http://consul:{PORT_CONSUL}/v1/catalog/service/products')
        if response.status_code == 200:
            services = response.json()
            if services:
                service = services[0]
                address = service.get('ServiceAddress') or service.get('Address')
                port = service.get('ServicePort')
                return f"http://{address}:{port}"
    except Exception as e:
        print(f"Error consultando a Consul: {e}")
    return None

@order_controller.route('/api/orders', methods=['GET'])
def get_orders():
    orders = Orders.query.all()
    result = [{
        'id': o.id,
        'user_id': o.user_id,
        'product_id': o.product_id,
        'quantity': o.quantity,
        'total': float(o.total)
    } for o in orders]
    return jsonify(result)

@order_controller.route('/api/orders', methods=['POST'])
def create_order():
    # En un entorno real, usarías session.get('username'). 
    # Para facilitar las pruebas sin login forzado, usamos un valor por defecto.
    user_name = session.get('username', 'Invitado') 
    
    data = request.get_json()
    products = data.get('products')
    
    if not products or not isinstance(products, list):
        return jsonify({'message': 'Falta la información de los productos'}), 400

    products_url = get_products_service_url()
    if not products_url:
        return jsonify({'message': 'Servicio de productos no disponible en Consul'}), 500

    productos_validados = []

    for item in products:
        prod_id = item.get('id')
        qty = item.get('quantity')

        try:
            prod_resp = requests.get(f"{products_url}/api/products/{prod_id}", timeout=5)
            if prod_resp.status_code == 404:
                return jsonify({'message': f'Producto no existe (ID: {prod_id})'}), 404
            elif prod_resp.status_code != 200:
                return jsonify({'message': 'Error al consultar producto'}), 500
                
            prod_data = prod_resp.json()
            
            if prod_data['stock'] < qty:
                return jsonify({'message': f'Inventario insuficiente. Stock actual: {prod_data["stock"]}'}), 409
                
            productos_validados.append({
                'id': prod_id, 
                'qty': qty, 
                'current_stock': prod_data['stock'], 
                'price': prod_data['price']
            })
            
        except requests.exceptions.RequestException:
            return jsonify({'message': 'Error de conexión con servicio de productos'}), 500

    try:
        for prod in productos_validados:
            new_stock = prod['current_stock'] - prod['qty']
            subtotal = prod['price'] * prod['qty']
            
            # Descontar inventario a través de la API descubierta por Consul
            update_resp = requests.put(f"{products_url}/api/products/{prod['id']}", json={'stock': new_stock}, timeout=5)
            if update_resp.status_code not in [200, 204]:
                return jsonify({'message': 'Error al actualizar el inventario'}), 500
            
            # Guardar la orden
            new_order = Orders(user_id=user_name, product_id=prod['id'], quantity=prod['qty'], total=subtotal)
            db.session.add(new_order)
            
        db.session.commit()
        return jsonify({'message': 'Orden creada exitosamente'}), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': 'Error interno al guardar la orden'}), 500

@order_controller.route('/api/orders/<int:order_id>', methods=['DELETE'])
def delete_order(order_id):
    order = Orders.query.get_or_404(order_id)
    db.session.delete(order)
    db.session.commit()
    return jsonify({'message': 'Order deleted successfully'})