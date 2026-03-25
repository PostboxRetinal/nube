from flask import Blueprint, request, jsonify
from products.models.product_model import Products
from db.db import db

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
    new_product = Products(
        name=data['name'],
        description=data.get('description'),
        price=data['price'],
        stock=data['stock']
    )
    db.session.add(new_product)
    db.session.commit()
    return jsonify({'message': 'Product created successfully'}), 201

@product_controller.route('/api/products/<int:product_id>', methods=['PUT'])
def update_product(product_id):
    product = Products.query.get_or_404(product_id)
    data = request.json
    product.name = data['name']
    product.description = data.get('description')
    product.price = data['price']
    product.stock = data['stock']
    db.session.commit()
    return jsonify({'message': 'Product updated successfully'})

@product_controller.route('/api/products/<int:product_id>', methods=['DELETE'])
def delete_product(product_id):
    product = Products.query.get_or_404(product_id)
    db.session.delete(product)
    db.session.commit()
    return jsonify({'message': 'Product deleted successfully'})
