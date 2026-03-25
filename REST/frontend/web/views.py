import os
from flask import Flask, render_template
from flask_cors import CORS

app = Flask(__name__)
CORS(app)
app.config.from_object('config.Config')

# Context processor para inyectar los puertos de las APIs en las plantillas
@app.context_processor
    
def inject_api_ports():
    return {
        'api_users_port': os.environ.get('API_USERS_PORT', '5002'),
        'api_products_port': os.environ.get('API_PRODUCTS_PORT', '5003')
    }

# Ruta para renderizar el template index.html
@app.route('/')
def index():
    return render_template('index.html')

# Ruta para renderizar el template users.html
@app.route('/users')
def users():
    return render_template('users.html')

@app.route('/products')
def products():
    return render_template('products.html')

@app.route('/editUser/<string:id>')
def edit_user(id):
    print("id recibido",id)
    return render_template('editUser.html', id=id)

@app.route('/editProduct/<string:id>')
def edit_product(id):
    print("id recibido", id)
    return render_template('editProduct.html', id=id)


if __name__ == '__main__':
    app.run()
