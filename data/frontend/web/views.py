from flask import Flask, render_template
from flask_cors import CORS

app = Flask(__name__)

CORS(app)
app.config.from_object('config.Config')

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
    app.run(host='0.0.0.0', port=5001, debug=True)
