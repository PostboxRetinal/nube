from flask import Flask, render_template
from flask_cors import CORS
import os

app = Flask(__name__)

CORS(app)
app.config.from_object('config.Config')

PORTS = {
    'PORT_USERS': os.getenv('PORT_USERS', '5002'),
    'PORT_PRODUCTS': os.getenv('PORT_PRODUCTS', '5003'),
    'PORT_ORDERS': os.getenv('PORT_ORDERS', '5004'),
}

# Ruta para renderizar el template index.html
@app.route('/')
def index():
    return render_template('index.html', **PORTS)

# Ruta para renderizar el template users.html
@app.route('/users')
def users():
    return render_template('users.html', **PORTS)

@app.route('/products')
def products():
    return render_template('products.html', **PORTS)

@app.route('/orders')
def orders():
    return render_template('orders.html', **PORTS)

@app.route('/editUser/<string:id>')
def edit_user(id):
    print("id recibido",id)
    return render_template('editUser.html', id=id, **PORTS)

@app.route('/editProduct/<string:id>')
def edit_product(id):
    print("id recibido", id)
    return render_template('editProduct.html', id=id, **PORTS)

@app.route('/editOrder/<string:id>')
def edit_order(id):
    print("id recibido", id)
    return render_template('editOrder.html', id=id, **PORTS)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT_FRONTEND', 5001)), debug=True)
