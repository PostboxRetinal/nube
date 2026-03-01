from flask import Blueprint, request, jsonify
from products.models.product_model import Products
from db.db import db
from exceptions import BadRequestError, InternalServerError

product_controller = Blueprint('product_controller', __name__)

@product_controller.route('/api/products', methods=['GET'])
def get_products():
    products = Products.query.all()
    result = [
        {
            'id': product.id,
            'name': product.name,
            'description': product.description,
            'price': float(product.price),
            'stock': product.stock
        }
        for product in products
    ]
    return jsonify(result)

@product_controller.route('/api/products/<int:product_id>', methods=['GET'])
def get_product(product_id):
    product = Products.query.get_or_404(product_id)
    return jsonify({
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'price': float(product.price),
        'stock': product.stock
    })

@product_controller.route('/api/products', methods=['POST'])
def create_product():
    data = request.json
    if not data:
        raise BadRequestError("No se enviaron datos para crear el producto.")
    new_product = Products(
        name=data['name'],
        description=data.get('description'),
        price=data['price'],
        stock=data['stock']
    )
    db.session.add(new_product)
    db.session.commit()
    return jsonify({'message': 'Product created successfully'}), 201

@product_controller.route('/api/products/<int:product_id>', methods=['PUT', 'OPTIONS'])
def update_product(product_id):
    if request.method == 'OPTIONS':
        return jsonify({'message': 'CORS preflight OK'}), 200

    product = Products.query.get_or_404(product_id)

    data = request.json
    if not data:
        raise BadRequestError("No se enviaron datos para actualizar.")

    product.name = data.get('name', product.name)
    product.description = data.get('description', product.description)

    if 'price' in data and data['price'] not in [None, ""]:
        try:
            product.price = float(data['price'])
        except ValueError:
            raise BadRequestError("El precio debe ser un número válido.")

    if 'stock' in data and data['stock'] not in [None, ""]:
        try:
            product.stock = int(data['stock'])
        except ValueError:
            raise BadRequestError("El stock debe ser un número entero.")

    try:
        db.session.commit()
        return jsonify({'message': 'Product updated successfully'}), 200
    except Exception:
        db.session.rollback()
        raise InternalServerError()

@product_controller.route('/api/products/<int:product_id>', methods=['DELETE'])
def delete_product(product_id):
    product = Products.query.get_or_404(product_id)
    db.session.delete(product)
    db.session.commit()
    return jsonify({'message': 'Product deleted successfully'})